require "rails_helper"

describe Membership do
  before(:each) do
    # stub reservations segment
    allow(SegmentAnalytics).to receive(:booking)
    allow(SegmentAnalytics).to receive(:unpaid_booking)
    allow(SegmentAnalytics).to receive(:recurring_reservation)
  end

  context "field validations" do
    let(:membership) { build(:membership) }

    describe "#start_time" do
      context "validate presence" do

        it "should add error when absent" do
          membership.start_time = nil
          expect(membership).not_to be_valid
          expect(membership.errors).to include(:start_time)
        end

        it "should be valid when present" do
          expect(membership).to be_valid
          expect(membership.errors).not_to include(:start_time)
        end
      end
    end

    describe "#end_time" do
      context "validate presence" do
        it "should add error when absent" do
          membership.end_time = nil
          expect(membership).not_to be_valid
          expect(membership.errors).to include(:end_time)
        end

        it "should be valid when present" do
          expect(membership).to be_valid
          expect(membership.errors).not_to include(:end_time)
        end

        it "should not be greater than start_time" do
          membership.end_time = membership.start_time.advance(days: -1)
          expect(membership).not_to be_valid
          expect(membership.errors).to include(:end_time)
        end

        it "should not have duration of more than two years" do
          membership.end_time = membership.start_time.advance(years: 2, days: 1)
          expect(membership).not_to be_valid
        end
      end
    end

    describe "#price" do
      context "validate presence" do
        it "should add error when absent" do
          membership.price = nil
          expect(membership).not_to be_valid
          expect(membership.errors).to include(:price)
        end

        it "should be valid when present" do
          expect(membership).to be_valid
          expect(membership.errors).not_to include(:price)
        end
      end

      it "should be greater or equal to 0" do
        membership.price = -1
        expect(membership).not_to be_valid

        membership.price = 0
        expect(membership).to be_valid
      end
    end
  end

  context "associations" do
    let(:membership) { build(:membership) }

    before do
      Time.use_zone(membership.venue.timezone) do
        membership.reservations << FactoryGirl.build(:reservation, court: membership.venue.courts.first, user: membership.user)
        membership.reservations << FactoryGirl.build(:reservation, court: membership.venue.courts.second, user: membership.user)
        membership.save!
      end
    end

    it "should belong to a user" do
      expect(Membership.reflect_on_association(:user).macro).to eq(:belongs_to)
      expect(membership.user).not_to be_nil
    end

    it "should belong to a venue" do
      expect(Membership.reflect_on_association(:venue).macro).to eq(:belongs_to)
      expect(membership.venue).not_to be_nil
    end

    it "should have many reservations" do
      expect(Membership.reflect_on_association(:reservations).macro).to eq(:has_many)
      expect(membership.reservations.length).to eq(2)
    end

    it "should have many membership_connectors" do
      expect(Membership.reflect_on_association(:membership_connectors).macro).to eq(:has_many)
      expect(membership.membership_connectors.length).to eq(2)
    end
  end

  describe "#make_reservations" do
    let(:membership) { build(:membership, note: 'by membership') }
    let(:court) { membership.venue.courts.first }
    let(:court_ids) { [court.id] }
    let(:time_params){
      # start_time = DateTime.now.utc.beginning_of_week.next_week.at_noon
      {
        start_time: membership.start_time,
        end_time: membership.start_time.advance(hours: 1),
        membership_start_time: membership.start_time,
        membership_end_time: membership.end_time
      }
    }

    context "negative tests" do
      it "should not create reservation after membership ends" do
        time_params[:start_time] = membership.end_time.advance(days: 1)

        membership.make_reservations(time_params, court_ids)
        expect(membership.reservations.count).to eq(0)
      end

      it "should not create reservations for past dates" do
        Time.use_zone(membership.venue.timezone) do
          time_params[:start_time] = DateTime.current.utc.advance(month: 1).change(hour: 10)
        end

        membership.make_reservations(time_params, court_ids)
        reservation_count = calculate_number_of_reservations(time_params, court)
        expect(membership.reservations.count).to eq reservation_count
      end
    end

    context "Positive tests" do
      it "should build reservations and assign note" do
        membership.make_reservations(time_params, court_ids)
        expect(membership.reservations.length).to be > 0
        expect(membership.reservations.last.note).to eq membership.note
      end

      context "should build correct number of reservations" do
        weeks = [-1, 0, 1, 2, 3, 4, 5]
        weeks.each do |week|
          it "if start_time is advanced by #{week} week" do
            time_params[:start_time] = time_params[:start_time].advance(weeks: week)
            time_params[:end_time] = time_params[:start_time].advance(hours: 1)
            reservation_count = calculate_number_of_reservations(time_params, court)
            membership.make_reservations(time_params, court_ids)
            expect(membership.reservations.length).to eq(reservation_count)
          end
        end

        it "should make a miximum of 104 (2 years) reservations" do
          max_number_of_reservations_for_two_years = 104 # 52 * 2 (2 years)
          time_params[:membership_end_time] = time_params[:membership_start_time].advance(years: 3.years)
          membership.make_reservations(time_params, court_ids)
          expect(membership.reservations.length).to be <= max_number_of_reservations_for_two_years
        end

        context "should build reservations with correct timings (whole year)" do
          before do
            membership.end_time = membership.start_time.advance(months: 12, hours: 1)
            time_params[:membership_end_time] = membership.end_time #rebase
          end

          it "where start_time and end_time are always the same (not affected by dst)" do
            membership.make_reservations(time_params, court_ids)

            Time.use_zone(membership.venue.timezone) do
              reservation_timings = membership.reservations.map{|r| r.start_time.in_time_zone.strftime("%H:%M") }.uniq
              expect(reservation_timings).to eq([ (time_params[:start_time].in_time_zone.strftime("%H:%M")) ])

              reservation_timings = membership.reservations.map{|r| r.end_time.in_time_zone.strftime("%H:%M") }.uniq
              expect(reservation_timings).to eq([ (time_params[:end_time].in_time_zone.strftime("%H:%M")) ])
            end
          end
        end
      end
    end


    context "no_overlapping_reservations" do
      context "without ignore_overlapping_reservations attribute" do
        it "should not create overlapping reservations" do
          membership.make_reservations(time_params, court_ids)
          expect{membership.save!}.not_to raise_error
          initial_reservations = membership.reservations.count

          # make reservations for the same timings
          membership.make_reservations(time_params, court_ids)
          expect{membership.save!}.to raise_error(ActiveRecord::RecordInvalid)
          expect(membership.reservations.count).not_to be > initial_reservations
        end
      end

      context "with ignore_overlapping_reservations attribute" do
        it "should create non-overlapping reservations without raising error" do
          membership.make_reservations(time_params, court_ids)
          expect{membership.save!}.not_to raise_error
          initial_reservations = membership.reservations.count

          # make reservations with overlapping timings
          membership.ignore_overlapping_reservations = true
          time_params[:membership_end_time] = time_params[:membership_end_time].advance(months: 1)
          membership.make_reservations(time_params, court_ids)
          expect{membership.save!}.not_to raise_error
          expect(membership.reservations.count).to be > initial_reservations
        end

        context 'reservation.destroy in #handle_overlapping_reservation' do
          before do
            membership.make_reservations(time_params, court_ids)
            membership.save
          end

          it 'should not create membership_connectors for invalid reservations' do
            initial_connectors_count = membership.membership_connectors.count
            # will build and destroy overlapping reservations
            membership.ignore_overlapping_reservations = true
            membership.make_reservations(time_params, court_ids)
            membership.save

            expect(membership.membership_connectors.reload.count).to eq initial_connectors_count
          end

          it 'should not delete membership together with invalid reservations' do
            # will build and destroy overlapping reservations
            membership.ignore_overlapping_reservations = true
            membership.make_reservations(time_params, court_ids)
            membership.save

            expect(Membership.find_by_id(membership.id)).not_to eq nil
          end
        end
      end
    end

    context "not_on_holiday" do
      let(:holiday_start_time) {
        Time.use_zone(membership.venue.timezone) do
          membership.start_time.advance(weeks: 3).change(hour: 6, minute: 0, second: 0)
        end
      }
      let(:holiday) { build(:holiday, courts: [court], start_time: holiday_start_time) }
      before do
        time_params[:start_time] = holiday_start_time.change(hour: 10, minute: 0, second: 0)
        time_params[:end_time] = time_params[:start_time].advance(hours: 1)
      end


      it "should make reservations without holidays and be valid" do
        membership.make_reservations(time_params, court_ids)

        expect(membership).to be_valid
        expect(membership.reservations.select(&:valid?).length).to eq membership.reservations.length
      end

      it "should not make reservation on holiday and be invalid" do
        holiday.save!
        membership.make_reservations(time_params, court_ids)

        expect(membership).not_to be_valid
        expect(membership.reservations.select(&:valid?).length).to eq membership.reservations.length - 1
      end
    end

    context "duration_policy" do
      context "duration policy -1 (any)" do
        before do
          court.update!(duration_policy: -1)
        end

        [20, 60, 120].each do |duration|
          it "should allow duration of #{duration}" do
            time_params[:end_time] = time_params[:start_time].advance(minutes: duration)
            membership.make_reservations(time_params, court_ids)
            expect{membership.save!}.not_to raise_error
            reservation_count = calculate_number_of_reservations(time_params, court)
            expect(membership.reservations.count).to eq reservation_count
          end
        end

      end

      context "fixed duration policy" do
        before do
          court.update!(duration_policy: 60)
        end

        it "should not allow duration less than duration policy" do
          time_params[:end_time] = time_params[:start_time].advance(minutes: 30)
          membership.make_reservations(time_params, court_ids)
          expect{ membership.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "should allow valid duration" do
          time_params[:end_time] = time_params[:start_time].advance(hours: 1)
          membership.make_reservations(time_params, court_ids)
          expect{ membership.save! }.not_to raise_error
        end
      end

    end

    context "start_time_policy" do
      context "should not apply for members" do
        before do
          time_params[:start_time] = time_params[:start_time].change(min: 10)
          time_params[:end_time] = time_params[:end_time].change(min: 10)
        end

        [:hour_mark, :half_hour_mark].each do |policy|
          it "test for #{policy}" do
            court.update!(start_time_policy: policy)

            membership.make_reservations(time_params, court_ids)
            expect{ membership.save! }.not_to raise_error
            reservation_count = calculate_number_of_reservations(time_params, court)
            expect(membership.reservations.count).to eq reservation_count
          end
        end
      end
    end


    context "court_active" do
      it "should not make reservation if inactive" do
        court.update!(active: false)

        membership.make_reservations(time_params, court_ids)
        expect{ membership.save! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(membership.reservations.count).to eq 0
      end

      it "should make reservation if active" do
        court.update!(active: true)

        membership.make_reservations(time_params, court_ids)
        expect{membership.save!}.not_to raise_error
        reservation_count = calculate_number_of_reservations(time_params, court)
        expect(membership.reservations.count).to eq reservation_count
      end
    end
  end


  describe "#handle_destroy" do
    let(:membership) { create(:membership) }
    let(:other_membership) { create(:membership, user: membership.user, venue: membership.venue) }

    before do
      start_time = membership.start_time.advance(weeks: 3)
      membership.reservations << create(:reservation,
                                        court: membership.venue.courts.first,
                                        user: membership.user,
                                        start_time: start_time)
      membership.reservations << create(:reservation,
                                        court: membership.venue.courts.second,
                                        user: membership.user,
                                        start_time: start_time)
      membership.save!

      other_membership.reservations << create(:reservation,
                                              court: other_membership.venue.courts.second,
                                              user: other_membership.user,
                                              start_time: start_time.advance(days: 1))
      other_membership.save!

      membership.handle_destroy
    end

    it "should delete current membership" do
      expect{ Membership.find(membership.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should delete associated membership_connectors" do
      expect(MembershipConnector.where(membership_id: membership.id)).to be_empty
    end

    it "should delete all future reservations for current membership" do
      future_reservation_count = membership.reservations.select {|r| r.start_time > Time.current.utc }.count
      expect(future_reservation_count).to eq(0)
    end

    it "should not delete other memberships" do
      expect(other_membership.reservations.count).to eq(1)
    end

    it "should not delete other membership connectors" do
      expect(other_membership.membership_connectors.count).to eq(1)
    end
  end

  describe "#handle_update" do
    let(:membership) { create(:membership, note: 'by membership') }
    let(:new_court_ids) { [membership.venue.courts[1].id] }
    # coach_ids should be ignored on update!
    let(:membership_params) { { price: membership.price + 10, note: 'new note', coach_ids: [2] } }

    before do
      court = membership.venue.courts.first
      start_time = membership.start_time
      end_time = membership.end_time

      time_params = {
        start_time: start_time.advance(days: 1),
        end_time: start_time.advance(days: 1, hours: 2),
        membership_start_time: start_time,
        membership_end_time: end_time
      }
      membership.make_reservations(time_params, [court.id])
      membership.save!

      # update membership
      @time_params = {
        membership_start_time: membership.start_time.in_time_zone.advance(days: 7).utc,
        membership_end_time: membership.end_time.in_time_zone.advance(days: 7).utc,
        start_time: time_params[:start_time].in_time_zone.advance(days: 7, hours: 1).utc,
        end_time: time_params[:end_time].in_time_zone.advance(days: 7, hours: 1).utc
      }
    end

    subject { membership.handle_update(membership_params, @time_params, new_court_ids) }

    it "should return true if success" do
      is_expected.to be_truthy
    end

    it 'does not update coaches' do
      expect { subject }.not_to change { membership.reservations.first.reload.coach_ids }
    end

    it "should update court and note" do
      is_expected.to be_truthy
      expect(membership.reservations.first.court.id).to eq(new_court_ids[0])
      expect(membership.reservations.first.note).to eq 'new note'
    end

    it "should delete existing future reservations and create new ones" do
      is_expected.to be_truthy
      court = Court.find(new_court_ids[0])
      reservation_count = calculate_number_of_reservations(@time_params, court)
      expect(membership.reservations.count).to eq reservation_count
    end

    it "should update membership timings" do
      is_expected.to be_truthy

      timezone = membership.venue.timezone
      reservations_start_time = @time_params[:start_time]
      while reservations_start_time < Time.current.utc
        reservations_start_time = reservations_start_time.in_time_zone(timezone).advance(weeks: 1)
      end
      reservations_end_time = reservations_start_time.in_time_zone.advance(hours: 2)
      membership.reload
      expect(membership.start_time).to eq(@time_params[:membership_start_time])
      expect(membership.end_time).to eq(@time_params[:membership_end_time])
      expect(membership.reservations.first.start_time).to eq reservations_start_time
      expect(membership.reservations.first.end_time).to eq reservations_end_time
    end
  end

end

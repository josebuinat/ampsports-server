require "rails_helper"

describe MembershipsController, type: :controller do
  before(:each) do
    # stub reservations segment
    allow(SegmentAnalytics).to receive(:booking)
    allow(SegmentAnalytics).to receive(:unpaid_booking)
    allow(SegmentAnalytics).to receive(:recurring_reservation)
  end

  describe "GET index" do

    let(:venue) { create :venue, :with_memberships, membership_count: 3 }

    context "without admin login" do
      it "should redirect html request to admin sign in page" do
        get :index, {venue_id: venue.id}
        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let(:admin) { create :admin }

      before do
        sign_in(admin)
        get :index, {venue_id: venue.id, format: :json}
      end

      it "should respond with success status 200" do
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "should respond with 'application/json'" do
        expect(response.content_type).to eq("application/json")
      end

      it "should respond with memberships list json body" do
        membership_response = JSON.parse(response.body)
        expect(membership_response).not_to be_blank
        expect(membership_response.count).to eq(venue.memberships.count)
      end

      it_behaves_like "set_venue"
    end
  end


  describe "GET show" do
    let(:venue) { create(:venue, :with_memberships, membership_count: 3) }
    let(:membership) { venue.memberships.first }

    context "without admin login" do
      it "should redirect html request to admin sign in page" do
        get :show, {:venue_id => venue.id, id: membership}
        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let(:admin) { create(:admin) }

      before do
        sign_in(admin)
        get :show, {:venue_id => venue.id, :id => membership, :format => "json"}
      end

      it "should respond with success status 200" do
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "should assign @membership" do
        expect(assigns(:membership)).to eq membership
      end

      it_behaves_like "set_venue"
    end
  end

  describe "POST create" do
    let!(:venue) { create(:venue, :with_courts, court_count: 2) }
    let!(:court) { venue.courts.first }
    let!(:params_hash) {
      in_venue_tz do
        {
          venue_id: venue.id,
          court_ids: court_ids,
          membership: {
            start_time: "10:00",
            end_time: "11:00",
            weekday: "Sunday",
            price: 10,
            start_date: 1.days.from_now.strftime("%d/%m/%Y"),
            end_date: 1.month.from_now.strftime("%d/%m/%Y")
          }
        }
      end
    }

    let!(:time_params) do
      in_venue_tz do
        MembershipTimeSanitizer.new(params_hash[:membership]).time_params
      end
    end

    let(:court_ids) { [court.id] }

    context "without admin login" do
      let(:user) { FactoryGirl.attributes_for(:user) }

      it "should redirect html request to admin sign in page" do
        post :create, params_hash
        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let(:admin) { create(:admin) }

      before do
        sign_in admin
      end

      context "with new user registration" do
        let(:user) { FactoryGirl.attributes_for(:user) }

        before do
          params_hash[:user] = user
          post :create, params_hash
        end

        it "should redirect to memberships_path(venue)" do
          expect(response).to redirect_to(memberships_path(venue))
        end

        it "should set success message" do
          expect(flash[:notice]).to be_present
        end

        it "should create new user" do
          expect(User.count).to eq(1)
        end

        it "should create new membership" do
          expect(Membership.count).to eq(1)
        end

        it "should create reservations" do
          membership = Membership.last
          expect(membership.reservations.count).to be > 1
        end

        it 'saves record in activiy log' do
          expect(ActivityLog.last.activity_type.to_s).to eq('membership_created')
        end

        it_behaves_like "set_venue"
      end

      context "with existing user" do
        let(:user) { create(:user) }
        before do
          venue.users << user
          venue.save!
          params_hash[:user] = { user_id: user.id }
        end

        context "with multiple courts" do
          let(:court2) { venue.courts.second }
          let (:court_ids) { [court.id, court2.id] }
          subject { post :create, params_hash }

          it "creates membership" do
            expect { subject }.to change(Membership, :count).by(1)
          end

          it "creates reservations for all courts" do
            expect { subject }.to change(court.reservations, :count)
                                    .and change(court2.reservations, :count)
          end
        end

        context "No errors" do
          before do
            post :create, params_hash
          end

          it "should redirect to memberships_path(venue)" do
            expect(response).to redirect_to(memberships_path(venue))
          end

          it "should set success message" do
            expect(flash[:notice]).to be_present
          end

          it "should not create new users" do
            expect(User.count).not_to be > 1
          end

          it "should create new membership" do
            expect(Membership.count).to eq(1)
          end

          it "should create reservations" do
            membership = Membership.last
            expect(membership.reservations.count).to be > 1
          end

          it_behaves_like "set_venue"
        end

        context "edge cases" do
          context "business hours" do
            before do
              params_hash[:membership][:start_time] = venue.closing(DateTime.tomorrow.strftime("%a").downcase)
              params_hash[:membership][:end_time] = params_hash[:membership][:start_time].to_time.advance(hours: 1).strftime("%H:%M")
              params_hash[:membership][:weekday] = DateTime.tomorrow.strftime("%A")
            end

            context "closing hours" do
              it "should not make reservation when timings across closing hour" do
                params_hash[:membership][:start_time] = venue.closing(DateTime.tomorrow.strftime("%a").downcase)
                params_hash[:membership][:end_time] = params_hash[:membership][:start_time].to_time.advance(hours: 1).strftime("%H:%M")

                post :create, params_hash
                expect(Reservation.count).to eq(0)
              end

              it "should make reservation when timings just before closing hour" do
                params_hash[:membership][:end_time] = venue.closing(DateTime.tomorrow.strftime("%a").downcase)
                params_hash[:membership][:start_time] = params_hash[:membership][:end_time].to_time.advance(hours: -1).strftime("%H:%M")

                post :create, params_hash
                expect(Reservation.count).to be > 0
              end
            end

            context "opening hours" do
              it "should not make reservation when timings across opening hour" do
                params_hash[:membership][:end_time] = venue.opening(DateTime.tomorrow.strftime("%a").downcase)
                params_hash[:membership][:start_time] = params_hash[:membership][:end_time].to_time.advance(hours: -1).strftime("%H:%M")

                post :create, params_hash
                expect(Reservation.count).to eq(0)
              end

              it "should make reservation when timings just after opening hour" do
                params_hash[:membership][:start_time] = venue.opening('sun')
                params_hash[:membership][:end_time] = params_hash[:membership][:start_time].to_time.advance(hours: 1).strftime("%H:%M")

                post :create, params_hash
                expect(Reservation.count).to be > 0
              end
            end
          end

          context "no overlapping reservation" do
            before do
              ActionMailer::Base.deliveries = []
              post :create, params_hash
            end

            it "should create membership" do
              expect(Membership.count).to eq(1)
            end

            it "should create correct number of reservations" do
              membership = Membership.first
              reservation_count = calculate_number_of_reservations(time_params, court)

              expect(membership.reservations.count).to eq reservation_count
            end

            it "should redirect to memberships_path" do
              expect(response).to redirect_to(memberships_path(venue))
            end

            it "should set success notice" do
              expect(flash[:notice]).to be_present
            end
          end

          context "overlapping reservation" do
            let!(:last_reservation_start_time) do
              in_venue_tz do
                MembershipTimeSanitizer.new(params_hash[:membership]).last_reservation_start_time
              end
            end

            let!(:other_reservation) {
              # adding older conflicting reservation
              create(:reservation, start_time: last_reservation_start_time, court: court)
            }

            context "Without ignore overlap parameter" do
              before do
                ActionMailer::Base.deliveries = []
                post :create, params_hash
              end

              it "should not create membership" do
                expect(Membership.count).to eq(0)
              end

              it "should not create any new reservations" do
                expect(Reservation.count).not_to be > 1
              end

              it "should render template 'venues/memberships'" do
                expect(response).to render_template('venues/memberships')
              end

              it "should set flash alert" do
                expect(flash[:alert]).to be_present
              end

              it "should not send any email" do
                expect(ActionMailer::Base.deliveries.count).to eq 0
              end
            end

            context "With ignore overlaps parameter" do
              before do
                params_hash.merge!({ignore_overlapping_reservations: true})
                ActionMailer::Base.deliveries = []
                post :create, params_hash
              end

              it "should create membership" do
                expect(Membership.count).to eq 1
              end

              it "should create non-overlapping reservations only" do
                membership = Membership.first
                reservation_count = calculate_number_of_reservations(time_params, court) - 1

                expect(membership.reservations.count).to eq reservation_count
              end

              it "should redirect to memberships_path" do
                expect(response).to redirect_to(memberships_path(venue))
              end

              it "should set success notice" do
                expect(flash[:notice]).to be_present
              end
            end
          end
        end

        context "on Errors" do
          before do
            params_hash[:membership][:price] = nil
            post :create, params_hash
          end

          it "should render to 'venues/memberships' template" do
            expect(response).to render_template('venues/memberships')
          end

          it "should set alert message" do
            expect(flash[:alert]).to be_present
          end
        end
      end
    end
  end

  describe "POST update" do
    let!(:venue) { create :venue }
    let!(:court) { create :court, venue: venue }
    let!(:new_court) { create :court, venue: venue }
    let!(:membership) { create(:membership, venue: venue) }
    let!(:params_hash) {
      in_venue_tz do
        {
          id: membership.id,
          venue_id: venue.id,
          court_ids: [new_court.id],
          membership: {
            start_time: TimeSanitizer.output(membership.start_time).advance(hours: 1).to_s(:time),
            end_time: TimeSanitizer.output(membership.start_time).advance(hours: 2).to_s(:time),
            weekday: TimeSanitizer.output(membership.start_time).strftime("%A"),
            price: membership.price + 10,
            start_date: TimeSanitizer.output(membership.start_time).advance(months: 1).to_s(:date),
            end_date: TimeSanitizer.output(membership.end_time).advance(months: 2).to_s(:date)
          }
        }
      end
    }
    let!(:time_params) { in_venue_tz { MembershipTimeSanitizer.new(params_hash[:membership]).time_params } }

    context "without admin login" do
      it "should redirect html request to admin sign in page" do
        post :update, params_hash
        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let(:admin) { create(:admin) }

      before do
        sign_in admin
      end

      context "without any prior reservations" do
        before do
          post :update, params_hash
        end

        it 'saves record in activiy log' do
          expect(ActivityLog.last.activity_type.to_s).to eq('membership_updated')
        end

        it_behaves_like "update membership"
        it_behaves_like "set_venue"
      end

      context "with prior reservations" do

        context "single court to multiple courts" do
          before do
            membership.make_reservations(time_params, [new_court.id])
            membership.save!
            params_hash[:court_ids] = [court.id, new_court.id]
          end

          it "should create reservations for the new court" do
            expect(membership.reservations.count).to eq(new_court.reservations.count)
            post :update, params_hash
            expect(Reservation.all.count).to eq(new_court.reservations.count * 2)
          end
        end

        context "multiple courts to single court" do
          before do
            membership.make_reservations(time_params, [venue.courts[1].id, court.id])
            membership.save!
            params_hash[:court_ids] = [court.id]
          end

          it "should create reservations for the new court" do
            expect(membership.reservations.count).to eq(new_court.reservations.count + court.reservations.count)
            post :update, params_hash
            expect(membership.reservations.reload.count).to eq(court.reservations.count)
          end
        end

        context "with paid reservations" do
          before do
            membership.make_reservations(time_params, [new_court.id, court.id])
            membership.reservations.select { |r| r.court_id == court.id }.first.payment_type = :paid
            membership.save!
            params_hash[:court_ids] = [new_court.id]
            post :update, params_hash
          end

          it "should not update membership and reservations if paid" do
            # all but paid reservations are removed for this court
            expect(membership.reservations.future.where(court_id: court.id)).to eq membership.reservations.future.paid
          end
        end

        context "number of reservations" do
          before do
            membership.assign_attributes(end_time: membership.end_time.advance(months: 1))
            membership.make_reservations(time_params, [court.id])
            membership.save!
            params_hash[:membership][:start_date] = TimeSanitizer.output(membership.end_time).advance(weeks: -4).to_s(:date)
            params_hash[:membership][:end_date] = TimeSanitizer.output(membership.end_time).advance(weeks: -2).to_s(:date)
            post :update, params_hash
          end

          it "should delete extra reservations" do
            membership.reload
            expect(Reservation.where(start_time: Time.now.utc..membership.start_time).count).to eq 0
            expect(Reservation.where('start_time > ?', membership.end_time).count).to eq 0
          end
        end
      end

      context "overlapping reservations" do
        let!(:last_reservation_start_time) do
          Time.use_zone(venue.timezone) do
            MembershipTimeSanitizer.new(params_hash[:membership]).last_reservation_start_time
          end
        end
        let!(:other_reservation) {
          court = Court.find(params_hash[:court_ids][0])
          create(:reservation, start_time: last_reservation_start_time, court: court)
        }

        context "without ignore overlap parameter" do
          before do
            ActionMailer::Base.deliveries = []
            post :update, params_hash
          end

          it "should render template 'venues/memberships'" do
            expect(response).to render_template('venues/memberships')
          end

          it "should set flash alert" do
            expect(flash[:alert]).to be_present
          end

          it "should not create any new reservations" do
            expect(Reservation.count).to eql 1
          end
        end

        context "With ignore overlaps parameter" do
          before do
            params_hash.merge!({ignore_overlapping_reservations: true})
            ActionMailer::Base.deliveries = []
            post :update, params_hash
          end

          it "should create non-overlapping reservations only" do
            reservation_count = calculate_number_of_reservations(time_params, new_court) - 1
            expect(membership.reservations.count).to eq reservation_count
          end

          it "should redirect to memberships_path" do
            expect(response).to redirect_to(memberships_path(venue))
          end

          it "should set success notice" do
            expect(flash[:notice]).to be_present
          end
        end
      end

      context "with errors" do
        before do
          params_hash[:membership][:price] = nil
          post :update, params_hash
        end

        it "should set error flash" do
          expect(flash[:alert]).to be_present
        end

        it "should not update the membership" do
          prev_membership = membership.dup
          membership.reload
          expect(membership.start_time).to eq(prev_membership.start_time)
          expect(membership.end_time).to eq(prev_membership.end_time)
          expect(membership.price).to eq(prev_membership.price)
        end
      end
    end
  end

  describe "DELETE destroy" do
    let(:membership) { create(:membership) }

    before do
      court = membership.venue.courts.first
      start_time = Time.use_zone(membership.venue.timezone) do
        DateTime.current.beginning_of_week.next_week.at_noon
      end
      time_params = {
        start_time: start_time,
        end_time: start_time.advance(hours: 1),
        membership_start_time: membership.start_time,
        membership_end_time: membership.end_time
      }
      membership.make_reservations(time_params, [court.id])
      membership.save!
    end

    context "without admin login" do
      before do
        delete :destroy, { id: membership.id, venue_id: membership.venue.id }
      end

      it "should redirect html request to admin sign in page" do
        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let(:admin) { create(:admin) }

      before do
        sign_in admin
        @test_referer = "testreferer"
        request.env["HTTP_REFERER"] = @test_referer
      end

      context "Positive tests" do
        before do
          params = { id: membership.id, venue_id: membership.venue.id }
          delete :destroy, params
        end

        it "should delete membership" do
          expect(Membership.count).to eq(0)
          expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "should redirect back to its referer" do
          expect(response).to redirect_to(@test_referer)
        end

        it "should set success message" do
          expect(flash[:notice]).to be_present
        end

        it "should delete all future reservations" do
          membership.reservations.reload
          future_reservation_count = membership.reservations.select { |r| r.start_time > Time.current.utc }.count
          expect(future_reservation_count).to eq(0)
        end

        it 'saves record in activiy log' do
          expect(ActivityLog.last.activity_type.to_s).to eq('membership_cancelled')
        end
      end

      context "Negative tests" do
        it "should handle ActiveResource::RecordNotFound" do
          # wrong membership id provided to test 404 error
          params = { id: membership.id + 1, venue_id: membership.venue.id }
          expect { delete :destroy, params }.not_to raise_error
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end

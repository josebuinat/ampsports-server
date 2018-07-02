require 'rails_helper'

RSpec.describe User, type: :model do
  it "works" do
    user = FactoryGirl.create(:user)
    expect(user).to be_valid
  end

  it "creates a stipe user id" do
    user = FactoryGirl.create(:user)
    VCR.use_cassette('stripe_create_token') do
      token = Stripe::Token.create( card: { number: "4242424242424242",
                                    exp_month: 1,
                                    exp_year: 2021,
                                    cvc: 314 } )
      user.add_stripe_id(token.id)
    end
    expect(user.has_stripe?).to eq(true)
  end

  context 'reservations queries' do
    let!(:membership) { create :membership }
    let(:venue) { membership.venue }
    let!(:user1) { membership.user }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:court1) { venue.courts.first }
    let!(:court2) { venue.courts.last }
    let!(:time) { membership.start_time.advance(weeks: 3).at_noon }
    let!(:past_time) { membership.start_time.advance(weeks: -1).at_noon }
    let!(:future_reservation1) { create :reservation,
                                        user: user1,
                                        court: court1,
                                        start_time: time
    }
    let!(:future_reservation2) { create :reservation,
                                        user: user2,
                                        court: court2,
                                        start_time: time
    }
    let!(:future_participating_reservation) { create :reservation,
                                                      user: user3,
                                                      participants: [user1],
                                                      court: court2,
                                                      start_time: time.tomorrow
    }
    let!(:past_reservation1) { create :novalidate_reservation,
                                      user: user1,
                                      court: court1,
                                      start_time: past_time
    }
    let!(:past_reservation2) { create :novalidate_reservation,
                                      user: user2,
                                      court: court2,
                                      start_time: past_time
    }
    let!(:past_participating_reservation) { create :novalidate_reservation,
                                                   user: user3,
                                                   participants: [user1],
                                                   court: court2,
                                                   start_time: past_time.yesterday
    }
    let!(:future_membership) { create :reservation,
                                      user: user1,
                                      court: court1,
                                      start_time: time + 1.days,
                                      booking_type: :membership,
                                      membership: membership
    }
    let!(:past_membership) { create :novalidate_reservation,
                                    user: user1,
                                    court: court2,
                                    start_time: past_time - 1.days,
                                    booking_type: :membership,
                                    membership: membership
    }
    let!(:future_reselling) { create :reservation,
                                     user: user1,
                                     court: court1,
                                     reselling: true,
                                     start_time: time + 2.days,
                                     booking_type: :membership,
                                     membership: membership
    }
    let!(:past_reselling) { create :novalidate_reservation,
                                   user: user1,
                                   court: court2,
                                   reselling: true,
                                   start_time: past_time - 2.days,
                                   booking_type: :membership,
                                   membership: membership
    }
    let!(:future_resold) { create :reservation,
                                  user: user2,
                                  court: court1,
                                  initial_membership_id: membership.id,
                                  start_time: time + 3.days
    }
    let!(:past_resold) { create :novalidate_reservation,
                                user: user2,
                                court: court2,
                                initial_membership_id: membership.id,
                                start_time: past_time - 3.days
    }
    let(:group) { create :group, venue: venue, owner: user3 }
    let(:coach) { create :coach, :available, company: venue.company, for_court: court1 }
    let!(:participated_group_reservation) {
      create :reservation, user: group, court: court1, start_time: time + 4.days
    }
    let!(:participation) {
      create :participation, user: user2, reservation: participated_group_reservation
    }
    let!(:coached_reservation) {
      create :reservation, user: user2, court: court2, start_time: time + 4.days, coaches: [coach]
    }
    let!(:participated_coached_reservation) {
      create :reservation, user: coach, court: court2, start_time: time + 5.days, participants: [user2]
    }

    describe '#normal_reservations' do
      it "should return own and participating_reservations excluding coached" do
        [user1, user2, user3].each do |user|
          expect(user.normal_reservations.to_a).to match_array(
            (user.reservations.non_coached +
             user.participating_reservations.non_coached).uniq)
        end
      end
    end

    describe '#future_reservations' do
      it 'should return only future non recurring reservations owned by this user' do
        expect(user1.future_reservations.to_a).to match_array [future_reservation1, future_participating_reservation]
      end
    end

    describe '#past_reservations' do
      it 'should return only past non recurring reservations owned by this user' do
        expect(user1.past_reservations.to_a).to match_array [past_reservation1, past_participating_reservation]
      end
    end

    describe '#future_memberships' do
      it 'should return only future not-reselling recurring reservations owned by this user' do
        expect(user1.future_memberships.to_a).to match_array [future_membership]
      end
    end

    describe '#past_memberships' do
      it 'should return only past not-reselling recurring reservations owned by this user' do
        expect(user1.past_memberships.to_a).to match_array [past_membership]
      end
    end

    describe '#reselling_memberships_future' do
      it 'should return only future reselling recurring reservations owned by this user' do
        expect(user1.reselling_memberships_future.to_a).to match_array [future_reselling]
      end
    end

    describe '#reselling_memberships_past' do
      it 'should return only past reselling recurring reservations owned by this user' do
        expect(user1.reselling_memberships_past.to_a).to match_array [past_reselling]
      end
    end

    describe '#resold_memberships' do
      it 'should return only resold recurring reservations initially owned by this user' do
        expect((user1.resold_memberships_future + user1.resold_memberships_past).to_a).to match_array [future_resold, past_resold]
      end
    end

    describe '#reservations_with_resold' do
      it 'should return reservations including resold initially owned by this user' do
        expect(user1.reservations_with_resold.to_a).to match_array (user1.reservations + [future_resold, past_resold])
      end
    end

    describe "#lessons" do
      it 'returns participaded group reservations or coached reservations' do
        expect(user2.lessons).to match_array([participated_group_reservation, coached_reservation, participated_coached_reservation])
      end
    end
  end

  describe 'validations' do
    describe 'passwords' do
      subject { user.tap { |x| x.assign_attributes(new_params) }.valid? }

      context 'when new user' do
        let!(:user) { build :user, :no_password }

        context 'without confirmation' do
          let(:new_params) { { password: '7@#&LA8234' } }

          it 'does not work' do
            is_expected.to be_falsey
            # In this case it will fire "can't be blank"
            expect(user.errors[:password_confirmation]).to be_present
          end
        end

        context 'with confirmation' do
          let(:new_params) { { password: '7@#&LA8234', password_confirmation: '7@#&LA8234' } }
          it { is_expected.to be_truthy }
        end
      end

      # because password and password_confirmation are virtual attributes (setter + getter)
      # we need to test existing model separately
      context 'with existing user' do
        let!(:user) { create :user }

        context 'with unimportant updates' do
          let(:new_params) { { first_name: 'yolo'} }
          it { is_expected.to be_truthy }
        end

        context 'without confirmation' do
          let(:new_params) { { password: '7@#&LA8234'} }
          it 'does not work' do
            is_expected.to be_falsey
            # in this case it will fire "doesn't match Password", that's the difference
            expect(user.errors[:password_confirmation]).to be_present
          end
        end

        context 'with confirmation' do
          let(:new_params) { { password: '7@#&LA8234', password_confirmation: '7@#&LA8234' } }
          it { is_expected.to be_truthy }
        end
      end

      it_behaves_like "configurable clock_type" do
        subject { User.new }
      end
    end
  end
end

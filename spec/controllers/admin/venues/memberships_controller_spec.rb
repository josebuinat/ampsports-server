require 'rails_helper'

describe Admin::Venues::MembershipsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_courts, court_count: 1, company: company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }
    let(:membership_ids) { body['memberships'].map { |x| x['id'] } }
    let!(:membership) { create :membership, :with_reservations, venue: venue }
    let!(:wrong_membership) { create :membership, :with_reservations }
    it 'works' do
      is_expected.to be_success
      expect(membership_ids).to eq [membership.id]
    end
  end

  describe '#show' do
    subject { get :show, format: :json, venue_id: venue.id, id: membership.id }
    let!(:membership) { create :membership, :with_reservations, venue: venue }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, membership: params }
    let!(:court) { create :court, venue: venue }
    let!(:my_other_venue) { create :venue, company: company }
    let!(:user) { create :user, venues: [my_other_venue] }
    let(:start_date) { 12.days.since.strftime('%d/%m/%Y') }
    let(:end_date) { 13.days.since.strftime('%d/%m/%Y') }
    let!(:coach) { create :coach, :available, for_court: court, company: venue.company }
    context 'with existing user' do
      context 'with valid params' do
        let(:params) do
          { court_ids: [court.id],
            **owner_params,
            price: 10,
            start_time: '12:00',
            end_time: '13:00',
            start_date: start_date,
            end_date: end_date,
            coach_ids: [coach.id]
          }
        end
        let(:owner_params) { { user_id: user.id } }
        let(:created_membership) { Membership.last }

        it 'creates a membership' do
          expect { subject }.to change { venue.memberships.count }.by(1)
          is_expected.to be_created
          expect(created_membership.user).to eq user
        end

        it 'assigns coach to all reservations' do
          is_expected.to be_created
          expect(created_membership.reservations).to satisfy { |reservations|
            reservations.all? { |x| x.coach_ids == [coach.id] }
          }
        end

        it 'associates user with venue' do
          expect(SegmentAnalytics).to receive(:user_added_to_venue_via_admin)
          expect(SegmentAnalytics).not_to receive(:admin_created_user)
          expect { subject }.to_not change { User.count }
          expect(venue.users.reload).to include user
        end

        context 'with many reservations created for group' do
          let!(:group_participants) { [ create(:user), create(:user) ] }
          let!(:group) { create :group, users: group_participants }
          let(:owner_params) { { group_id: group.id } }
          let(:end_date) { 26.days.since.strftime('%d/%m/%Y') }

          it 'creates many reservations' do
            expect { subject }.to change { Reservation.count }.by(3)
          end

          it 'does not spam users' do
            group_participants.each do |participant|
              expect(MembershipMailer).to receive(:membership_created).
                  at_most(:twice).with(participant, instance_of(Membership)).and_call_original
            end
            expect(ReservationMailer).not_to receive(:participant_added_for_participant)
            # 2 for users, 1 for a coach
            expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(3)
          end
        end

        it_behaves_like "loggable activity", "membership_created"
      end

      context 'with group owner' do
        let(:params) do
          { court_ids: [court.id],
            group_id: group.id,
            price: 10,
            start_time: '12:00',
            end_time: '13:00',
            start_date: start_date,
            end_date: end_date
          }
        end
        let(:group) { create :group, venue: venue }

        it 'creates a membership' do
          expect { subject }.to change { venue.memberships.count }.by(1)
          is_expected.to be_created
          expect(Membership.last.user).to eq group
        end
      end

      context 'with invalid params' do
        context 'without price' do
          let(:params) do
            {
              court_ids: [court.id],
              user_id: user.id,
              start_time: '12:00',
              end_time: '13:00',
              start_date: start_date,
              end_date: end_date
            }
          end
          it 'does not work' do
            expect { subject }.to do_not_change { Membership.count }.and do_not_change { User.count }
            is_expected.to be_unprocessable
          end
        end
        context 'without courts' do
          let(:params) do
            {
              user_id: user.id,
              start_time: '12:00',
              end_time: '13:00',
              start_date: start_date,
              end_date: end_date
            }
          end
          it 'does not work' do
            is_expected.to be_unprocessable
          end
        end
      end
    end

    context 'when creating a new user' do
      let(:params) do
        {
          court_ids: [court.id],
          price: 10,
          start_time: '12:00',
          end_time: '13:00',
          start_date: start_date,
          end_date: end_date,
          user: user_attributes
        }
      end

      context 'with valid params' do
        let(:user_attributes) { { first_name: 'Hello', last_name: 'World', email: 'hello@there.ca' } }
        let(:created_user) { venue.users.last }
        let(:created_membership) { venue.memberships.last }

        it 'creates a membership' do
          expect { subject }.to change { venue.memberships.count }.by(1)
          is_expected.to be_created
        end

        it 'creates a user' do
          expect(SegmentAnalytics).to receive(:user_added_to_venue_via_admin)
          expect(SegmentAnalytics).to receive(:admin_created_user)
          expect { subject }.to change { venue.users.count }.by(1)
          expect(created_user.attributes.slice(*%w(first_name last_name email))).to eq user_attributes.stringify_keys
          expect(venue.users.reload).to include created_user
        end

        context 'when such user is already existed in the system' do
          let!(:existing_user) { create :user, email: user_attributes[:email], first_name: 'Bobby', last_name: 'Brown' }

          it 'does not create a new user' do
            expect { subject }.to_not change { User.count }
          end

          it 'connects user to the venue' do
            expect { subject }.to change { venue.users.count }.by(1).
                and change { venue.users.reload.include?(existing_user) }.from(false).to(true)
          end

          it 'creates membership and links it to the user' do
            is_expected.to be_success
            expect(created_membership.user).to eq existing_user
          end
        end
      end

      context 'with invalid params' do
        let(:user_attributes) { { first_name: 'Hello' } }
        it 'does not work' do
          expect { subject }.to do_not_change { Membership.count }.and do_not_change { User.count }
          is_expected.to be_unprocessable
        end
      end
    end

  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: membership.id, membership: params }
    let!(:user) { create :user, venues: [venue] }
    let!(:membership) { create :membership, venue: venue, user: user }
    let!(:court) { create :court, venue: venue }
    let(:start_date) { 12.days.since.strftime('%d/%m/%Y') }
    let(:end_date) { 13.days.since.strftime('%d/%m/%Y') }
    context 'with valid params' do
      let(:params) do
        { court_ids: [court.id], user_id: user.id, price: 10,
          start_time: '12:00', end_time: '13:00', start_date: start_date, end_date: end_date }
      end

      it 'updates a membership' do
        expect { subject }.to change { membership.reload.price }.to(10)
        is_expected.to be_success
      end

      context 'with many reservations created for group' do
        let!(:group_participants) { [ create(:user), create(:user) ] }
        let!(:group) { create :group, users: group_participants }
        let!(:user) { group }

        let(:end_date) { 26.days.since.strftime('%d/%m/%Y') }

        it 'does not spam users' do
          group_participants.each do |participant|
            expect(MembershipMailer).to receive(:membership_updated).
              at_most(:twice).with(participant, membership).and_call_original
          end
          expect(ReservationMailer).not_to receive(:reservation_updated)
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end
      end


      it_behaves_like "loggable activity", "membership_updated"
    end

    context 'with invalid params' do
      let(:params) do
        { court_ids: [court.id], user_id: user.id, price: 10,
        start_time: '16:00', end_time: '13:00', start_date: start_date, end_date: end_date }
      end
      it 'does not work' do
        expect { subject }.to do_not_change { membership.reload.attributes }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    let!(:user) { create :user, venues: [venue] }
    let!(:membership) { create :membership, venue: venue, user: user }
    subject { delete :destroy, format: :json, venue_id: venue.id, id: membership.id }

    it 'works' do
      expect { subject }.to change { venue.memberships.count }.by(-1)
      is_expected.to be_success
    end

    it_behaves_like "loggable activity", "membership_cancelled"
  end

  describe '#destroy_many' do
    subject { delete :destroy_many, format: :json, venue_id: venue.id, membership_ids: membership_ids }
    let!(:user) { create :user, venues: [venue] }
    let!(:membership_1) { create :membership, venue: venue, user: user }
    let!(:membership_2) { create :membership, venue: venue, user: user }
    let(:membership_ids) { [membership_1.id, membership_2.id] }
    it 'works' do
      expect { subject }.to change { venue.memberships.count }.by(-2)
      is_expected.to be_success
    end

    it_behaves_like "loggable activity", "membership_cancelled"
  end

  describe 'POST #import' do
    subject { post :import, venue_id: venue.id, csv_file: users_csv_file }

    let!(:user) { create :user, email: 'example@mail.com', venues: [venue] }
    let(:users_csv_file) { fixture_file_upload('import/memberships.csv', 'text/csv') }

    it 'imports memberships' do
      expect { subject }.to change { venue.memberships.count }.by(1)
      is_expected.to be_created
    end

    it 'returns report JSON' do
      is_expected.to be_created
      expect(body.dig('report', 'created_count')).to eq 1
      expect(body.dig('report', 'failed_count')).to eq 1
      expect(body.dig('report', 'failed_rows')).to be_any
      expect(body.dig('report', 'failed_rows')[0]['errors']).to be_present
    end
  end
end

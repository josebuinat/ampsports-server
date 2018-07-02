require 'rails_helper'

RSpec.describe GroupSeason, type: :model do
  let!(:venue) { create :venue, :with_users, :with_courts, court_counts: 2 }
  let!(:user) { venue.users.first }

  describe 'after_create :find_or_create_subscription, if: :seasonal?' do
    subject { create :group_member, group: group }

    let!(:group) { create :group, venue: venue, priced_duration: :season }
    let!(:current_season) { create :group_season, group: group, current: true }

    it 'create subscription for season' do
      expect{ subject }.to change { current_season.group_subscriptions.count }.by(1)
    end
  end

  describe '#after_create :create_participations' do
    subject {  create :group_member, group: group }

    context 'non seasonal group' do
      let!(:group) { create :group, venue: venue, owner: create(:admin) }
      let!(:existing_member) { create :group_member, group: group }
      let!(:reservation1) { create :reservation, user: group, court: venue.courts.first }
      let!(:reservation2) { create :reservation, user: group, court: venue.courts.second }

      it 'creates participations in reservations for member' do
        expect{ subject }.to change{ reservation1.participations.count }.by(1)
                         .and change{ reservation2.participations.count }.by(1)

        expect(subject.user).to eq reservation2.participations.last.user
      end
    end

    context 'seasonal group' do
      let!(:group) { create :group, venue: venue, priced_duration: :season }
      let!(:group_season) { create :group_season, group: group, current: true }
      let!(:paid_member) { create(:group_member, group: group).
                            tap { |member| member.subscriptions.last.mark_paid } }
      let!(:reservation) { create :reservation, user: group, court: venue.courts.first }

      it 'does not create participations(do not have paid subscription yet)' do
        expect{ subject }.to change { reservation.participations.count }.by(1)
      end
    end
  end

  describe 'mailers' do
    let!(:group) { create :group, users: [ user ] }

    context 'when adding new user' do
      let!(:new_user) { create :user }
      subject { group.users << new_user }

      before do
        expect(GroupMailer).to receive(:added_to_the_group).with(group, new_user)
          .at_most(:twice).and_call_original
      end

      it 'mails the user when he is added to the group' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when removing a user' do
      subject { group.update_attributes! members: [ ] }

      before do
        expect(GroupMailer).to receive(:removed_from_the_group).with(group, user)
          .at_most(:twice).and_call_original
      end

      it 'mails the user when he is removed from the group' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end

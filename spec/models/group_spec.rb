require 'rails_helper'

RSpec.describe Group, type: :model do
  let!(:group) { build :group }

  it 'can be created' do
    expect{group.save}.not_to raise_error
  end

  context 'associations' do
    describe "#company" do
      let!(:venue) { create :venue }
      let!(:group) { create :group, venue: venue }

      it "returns venue company" do
        expect(group.company.present?).to be_truthy
        expect(group.company).to eq venue.company
        expect(venue.company.reload.groups).to include(group)
      end
    end

    describe "#owner" do
      context "polymorphic association" do
        let(:admin) { create :admin }
        let(:user) { create :user }

        it "saves and returns user" do
          group.owner = user
          group.save
          group.reload

          expect(group.owner).to eq user
        end

        it "saves and returns admin" do
          group.owner = admin
          group.save
          group.reload

          expect(group.owner).to eq admin
        end
      end
    end

    describe "#coaches" do
      let!(:coach) { create :coach }
      let!(:group) { create :group, coaches: [coach] }

      context "association for coaches" do
        it "saves and returns coaches" do
          expect(group.reload.coaches).to be_any
          expect(group.coaches).to include coach
        end
      end
    end

    describe "#reservations" do
      let!(:group) { create :group }
      let!(:reservation) { create :reservation, user: group }

      context "reverse association for user" do
        it "returns associated" do
          expect(group.reload.reservations).to include(reservation)
          expect(reservation.reload.user).to eq group
        end
      end
    end

    describe '#members' do
      let!(:user) { create :user }
      let!(:group) { create :group }

      context 'create and return members' do
        it 'creates member' do
          expect{ group.members.create(user: user) }.to change{ GroupMember.count }.by(1)
        end

        it 'returns member' do
          group.members.create(user: user)

          expect(group.members.first.user).to eq user
        end
      end

      context 'members uniqueness' do
        let!(:user2) { create :user }
        let!(:group_member) { group.members.create(user: user) }

        it 'creates new member with different user' do
          expect{ group.members.create(user: user2) }.to change{ GroupMember.count }.by(1)
        end

        it 'does not create member with same user' do
          group.members.create(user: user)

          expect{ group.members.create(user: user) }.not_to change{ GroupMember.count }
        end
      end

      context 'members cant exeed max participants' do
        let!(:group_member1) { create :group_member, group: group }
        let!(:group_member2) { create :group_member, group: group }

        before(:each) do
          group.update_attribute(:max_participants, 2)
        end

        it 'does not create member if full' do
          member = group.members.build(user: user)

          error = I18n.t('activerecord.errors.models.group_member.attributes.group.group_is_full')

          expect(member).not_to be_valid
          expect(member.errors).to include(:group)
          expect(member.errors.messages[:group]).to include(error)
        end
      end

      describe 'created member automatically gets subscription to current season' do
        subject { group.members.create(user: user) }

        let(:user) { create :user }
        let!(:group) { create :group, priced_duration: :season }

        context 'group has current season' do
          let!(:season) { create :group_season, group: group, current: true }

          it 'creates subscription for added member' do
            expect{ subject }.to change(GroupSubscription, :count)

            subscription = group.subscriptions.last
            expect(subscription.user).to eq subject.user
            expect(subscription.start_date).to eq season.start_date
            expect(subscription.end_date).to eq season.end_date
          end
        end

        context 'group does not have current season' do
          let!(:season) { create :group_season, group: group, current: false }

          it 'creates subscription for added member' do
            expect{ subject }.not_to change(GroupSubscription, :count)
          end
        end
      end
    end

    describe '#custom_biller' do
      let!(:group) { create :group, :with_custom_biller }

      it 'nullifies custom_biller_id after biller destroy' do
        custom_biller = GroupCustomBiller.find(group.custom_biller.id)
        custom_biller.destroy

        expect(group.reload.custom_biller_id).to eq nil
      end

      context 'after_destroy :delete_custom_biller_without_groups' do
        context 'one group' do
          it 'deletes custom biller' do
            expect{group.destroy}.to change(GroupCustomBiller, :count).by(-1)
          end
        end

        context 'more than one group' do
          let!(:other_group) { create :group, custom_biller: group.custom_biller }

          it 'does not delete custom biller' do
            expect{group.destroy}.not_to change(GroupCustomBiller, :count)
          end
        end
      end
    end
  end

  context 'validations' do
    describe "#venue" do
      context "validate presence" do
        it "adds error when absent" do
          group.venue = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:venue)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end

    describe "#owner" do
      context "validate presence" do
        it "adds error when absent" do
          group.owner = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:owner)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end

    describe "#name" do
      context "validate presence" do
        it "adds error when absent" do
          group.name = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:name)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end

    describe "#classification" do
      context "validate presence" do
        it "adds error when absent" do
          group.classification = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:classification)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end

    describe "#participation_price" do
      context "validate presence" do
        it "adds error when absent" do
          group.participation_price = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:participation_price)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end

    describe "#max_participants" do
      context "validate presence" do
        it "adds error when absent" do
          group.max_participants = nil

          expect(group).not_to be_valid
          expect(group.errors).to include(:max_participants)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end

      context "validate integer" do
        it "adds error when not a number" do
          group.max_participants = 'df'

          expect(group).not_to be_valid
          expect(group.errors).to include(:max_participants)
        end

        it "adds error when not an integer" do
          group.max_participants = 0.5

          expect(group).not_to be_valid
          expect(group.errors).to include(:max_participants)
        end

        it "is valid when integer" do
          group.max_participants = 333

          expect(group).to be_valid
        end
      end
    end

    describe "#skill_levels" do
      context "validate presence of one" do
        it "adds error when absent" do
          group.skill_levels = []

          expect(group).not_to be_valid
          expect(group.errors).to include(:skill_levels)
        end

        it "is valid when present" do
          expect(group).to be_valid
        end
      end
    end
  end

  context 'scopes' do
    describe "#accepts_classification" do
      subject{ Group.accepts_classification(classification) }

      let(:classification) { create :group_classification }

      context "when primary classification" do
        let!(:group) { create :group, classification: classification }

        it "returns group" do
          is_expected.to include(group)
        end
      end

      context "when not primary classification" do
        let!(:group) { create :group }

        it "does not return group" do
          is_expected.not_to include(group)
        end
      end
    end

    describe "#accepts_skill_level" do
      subject{ Group.accepts_skill_level(6.5) }

      context "when has skil level" do
        let!(:group) { create :group, skill_levels: [6.5] }

        it "returns group" do
          is_expected.to include(group)
        end
      end

      context "when does not have skil level" do
        let!(:group) { create :group, skill_levels: [3] }

        it "does not return group" do
          is_expected.not_to include(group)
        end
      end
    end
  end

  describe 'destroying' do
    let!(:coach) { create :coach }
    let!(:group) { create :group, coaches: [coach] }

    subject { group.destroy }

    it 'removes the link between group and coach' do
      expect { subject }.to change { Group::CoachConnection.count }.by(-1)
    end

    it 'does not touch the coach' do
      expect { subject }.not_to change { Coach.count }
    end
  end

end

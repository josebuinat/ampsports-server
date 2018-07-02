require 'rails_helper'

RSpec.describe GroupSeason, type: :model do
  let!(:venue) { create :venue, :with_users }
  let!(:user) { venue.users.first }
  let!(:group) { create :group, venue: venue, priced_duration: :season }
  let!(:group_season) { build :group_season, group: group }

  it 'can be created' do
    expect{group_season.save}.not_to raise_error
  end

  context 'validations' do
    describe "#group" do
      context "validate presence" do
        it "adds error when absent" do
          group_season.group = nil

          expect(group_season).not_to be_valid
          expect(group_season.errors).to include(:group)
        end

        it "is valid when present" do
          expect(group_season).to be_valid
        end
      end

      context "validate seasonal group" do
        it "adds error when not a seasonal group" do
          group_season.group.priced_duration = :session

          error = I18n.t('activerecord.errors.models.group_season.attributes.group.not_seasonal')

          expect(group_season).not_to be_valid
          expect(group_season.errors).to include(:group)
          expect(group_season.errors.messages[:group]).to include(error)
        end

        it "is valid when seasonal group" do
          expect(group_season).to be_valid
        end
      end
    end

    describe "#start_date" do
      context "validate presence" do
        it "adds error when absent" do
          group_season.start_date = nil

          expect(group_season).not_to be_valid
          expect(group_season.errors).to include(:start_date)
        end

        it "is valid when present" do
          expect(group_season).to be_valid
        end
      end
    end

    describe "#end_date" do
      context "validate presence" do
        it "adds error when absent" do
          group_season.end_date = nil

          expect(group_season).not_to be_valid
          expect(group_season.errors).to include(:end_date)
        end

        it "is valid when present" do
          expect(group_season).to be_valid
        end
      end
    end

    describe '#validate_overlapping' do
      let!(:season) { create :group_season, group: group }
      let(:new_season) { build :group_season, group: group, start_date: new_season_start, end_date: new_season_end }

      context "overlapping season" do
        context 'has overlapped start' do
          let(:new_season_start) { season.start_date + 10.days }
          let(:new_season_end) { season.end_date + 10.days }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end

        context 'has overlapped end' do
          let(:new_season_start) { season.start_date - 80.days }
          let(:new_season_end) { season.end_date - 80.days }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end

        context "overlapping existing season end by one day" do
          let(:new_season_start) { season.end_date }
          let(:new_season_end) { season.end_date + 90.days }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end

        context "overlapping existing season start by one day" do
          let(:new_season_start) { season.start_date - 90.days }
          let(:new_season_end) { season.start_date }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end

        context 'wrapped by longer season' do
          let(:new_season_start) { season.start_date + 10.days }
          let(:new_season_end) { season.end_date - 10.days }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end

        context 'wrapping shorter season' do
          let(:new_season_start) { season.start_date - 10.days }
          let(:new_season_end) { season.end_date + 10.days }

          it "adds error" do
            expect(new_season).not_to be_valid
            expect(new_season.errors).to include(:start_date)
          end
        end
      end

      context "back to back season" do
        context "not overlapped by earlier season" do
          let(:new_season_start) { season.end_date + 1.days }
          let(:new_season_end) { season.end_date + 91.days }

          it "does not add error" do
            expect(new_season).to be_valid
          end
        end

        context "not overlapped by later season" do
          let(:new_season_start) { season.start_date - 91.days }
          let(:new_season_end) { season.start_date - 1.days }

          it "does not add error" do
            expect(new_season).to be_valid
          end
        end
      end

      context 'updating season' do
        it "does not overlapping self" do
          expect(season).to be_valid
        end
      end
    end
  end

  describe '#before_save :set_one_current' do
    let!(:season) { create :group_season, group: group, current: true }

    context 'same group' do
      let!(:new_season) {
        create :group_season, group: group, current: true, start_date: season.end_date.advance(days: 1)
      }

      it 'resets current for other season' do
        expect(new_season.reload).to be_current
        expect(season.reload).not_to be_current
      end

      it 'resets current to updated as current season' do
        season.reload.update_attribute(:current, true)

        expect(new_season.reload).not_to be_current
        expect(season.reload).to be_current
      end

      it 'does not reset current if updated not as current season' do
        season.reload.update_attribute(:start_date, season.start_date.advance(days: 1))

        expect(new_season.reload).to be_current
        expect(season.reload).not_to be_current
      end
    end

    context 'other group' do
      let!(:new_season) {
        create :group_season, current: true, start_date: season.end_date.advance(days: 1),
                  group: create(:group, priced_duration: :season)
      }

      it 'does not reset current for other group seasons' do
        expect(new_season.reload).to be_current
        expect(season.reload).to be_current
      end
    end
  end

  describe '#after_save :create_subscriptions, if: :became_current?' do
    let!(:member) { group.members.create(user: user) }
    let!(:season) { build :group_season, group: group, current: true }

    context 'current season added' do
      context 'member does not have matching subscription' do
        it 'creates subscription' do
          expect{ season.save }.to change(GroupSubscription, :count)

          subscription = group.subscriptions.last
          expect(subscription.user).to eq member.user
          expect(subscription.start_date).to eq season.start_date
          expect(subscription.end_date).to eq season.end_date
        end
      end
    end

    context 'current season changed' do
      subject{ updated_season.update(current: true) }
      let!(:updated_season) {
        create :group_season, group: group, current: false, start_date: season.end_date.advance(days: 1)
      }

      before(:each) do
        season.current = false
        season.save
      end

      context 'member does not have matching subscription' do
        it 'creates subscription' do
          expect{ subject }.to change(GroupSubscription, :count)

          subscription = group.subscriptions.last
          expect(subscription.user).to eq member.user
          expect(subscription.start_date).to eq updated_season.start_date
          expect(subscription.end_date).to eq updated_season.end_date
        end
      end

      context 'member has matching subscription' do
        before(:each) do
          GroupSubscription.create(group_season: updated_season, user: user)
        end

        it 'does not create subscription' do
          expect{ subject }.not_to change(GroupSubscription, :count)
        end
      end
    end
  end
end

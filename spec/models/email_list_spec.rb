require 'rails_helper'

describe EmailList do
  let(:venue) { create :venue }
  let(:email_list) { create(:email_list, :with_users, venue: venue) }
  let(:unsubscribed_user) { user = create :user,
                                           venues: [venue],
                                           unsubscribe_venue_emails: true }

  context "associations" do
    it "should belong to a venue" do
      expect(EmailList.reflect_on_association(:venue).macro).to eq(:belongs_to)
    end

    it "should have many users" do
      expect(EmailList.reflect_on_association(:users).macro).to eq(:has_many)
    end
  end

  context "field validations" do
    let(:email_list) { build(:email_list, venue: venue) }

    describe "#name" do
      context "validate presence" do
        it "should add error when absent" do
          email_list.name = ""
          expect(email_list.valid?).to be_falsy
          expect(email_list.errors).to include(:name)
        end

        it "should be valid when present" do
          expect(email_list.valid?).to be_truthy
          expect(email_list.errors).not_to include(:name)
        end
      end

      context "uniqueness" do
        let!(:email_list_2) { create(:email_list, venue: venue) }

        it "should add error when duplicate name" do
          email_list.name = email_list_2.name
          expect(email_list.valid?).to be_falsy
          expect(email_list.errors).to include(:name)
        end
      end
    end

    describe "#users" do
      let!(:user) {create(:user) }
      context "unique users?" do
        it "shouldn't allow duplicate users" do
          email_list.users << [user] * 2
          expect(email_list.valid?).to be_falsy
          expect(email_list.errors).to include(:users)
        end
      end
    end
  end

  describe "#add_users" do
    let(:user_list) { create_list(:user, 3, venues: [venue]) }

    it "should add new users" do
      user_ids = user_list.map(&:id)
      original_user_count = email_list.users.count
      email_list.add_users(user_ids)

      expect(email_list.users.count).to eq(original_user_count + user_list.count)
    end

    it "should not add duplicate users" do
      user_ids = user_list.map(&:id)
      user_ids.push(email_list.users.first.id)
      user_ids.push(user_list.first.id)
      original_user_count = email_list.users.count
      email_list.add_users(user_ids)

      expect(email_list.users.count).to eq(original_user_count + user_list.count)
    end

    it "should add email subscribed users only" do
      unsubscribed_user
      email_list.add_users(venue.users.reload.map(&:id))

      expect(email_list.user_ids).not_to include(unsubscribed_user.id)
    end
  end

  describe "#off_list_users" do
    let(:user_list) { create_list(:user, 5, venues: [venue]) }

    it "should return users of the venue not in the email list" do
      count = user_list.count
      result = email_list.off_list_users
      expect(result.count).to eq(count)
    end
  end

  describe "#add_all_users" do
    let!(:user_list) { create_list(:user, 3, venues: [venue]) }
    let!(:unsubscribed_user) { user = create :user,
                                             venues: [venue],
                                             unsubscribe_venue_emails: true }

    it "adds all users (subscribed)" do
      email_list.add_all_users

      expect(email_list.user_ids).to match_array venue.users.subscription_enabled.map(&:id)
      expect(email_list.user_ids).not_to include unsubscribed_user.id
    end
  end
end

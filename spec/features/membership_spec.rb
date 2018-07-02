require 'rails_helper'

feature "memberships", js: true do

  context "without admin login" do
    before do
      visit venue_memberships_path(venue_id: 99)
    end

    it "should be http success" do
      expect(page.status_code).to eq(200)
    end

    it "shows admin sign in page" do
      expect(page).to have_current_path(new_admin_session_path)
    end
  end

  context "with admin login" do
    let(:company) { create :company }
    let!(:venue) { create :venue, :with_courts, company: company }
    let!(:admin) { create :admin, :with_company, company: company }
    let!(:membership) { create :membership, venue: venue }
    let(:user) { membership.user }
    let!(:user2) { create :user }
    let!(:user3) { create :user }

    before do
      venue.users << user2 << user3
      venue.save

      visit venue_memberships_path(venue_id: venue)
      fill_in "admin[email]", with: admin.email
      fill_in "admin[password]", with: admin.password
      page.execute_script("$('form#new_admin').submit()")
      sleep(2)
    end

    it "should sign in" do
      expect(page).to have_current_path(venue_memberships_path(venue_id: venue.id))
    end

    it "should be have text 'Memberships'" do
      expect(page).to have_content(company.company_legal_name)
    end

    it "should have venue name" do
      expect(page).to have_text(venue.venue_name)
    end

    it "should have membership list" do
      expect(page).to have_selector("table tbody tr", count: venue.memberships.count)
      expect(page.all("table tbody tr").first).to have_text(membership.user.first_name)
    end

    context "Create new membership" do
      context "with existing user" do
        let(:membership_params) {
          {
            price: 20,
            start_time: "10:00",
            end_time: "11:00",
            weekday: "monday",
            start_date: DateTime.tomorrow.in_time_zone.strftime("%d/%m/%Y"),
            end_date: 1.month.from_now.in_time_zone.strftime("%d/%m/%Y")
          }
        }

        it "should create new membership" do
          create_membership(membership_params, venue, user2)

          expect(page).to have_current_path(venue_memberships_path(venue_id: venue.id))
          expect(page).to have_selector(".toast-info")
          expect(page).to have_selector("table tbody tr", count: venue.memberships.count)
          expect(page.all("table tbody tr").first).to have_text(membership.user.first_name)
          expect(page).to have_selector("table tbody tr", text: user2.first_name)
          expect(Membership.count).to eq(2)
          expect(Reservation.count).to eq(user2.reservations.count)
        end

        it "should ask to ignore overlapping reservations" do
          # create a membership
          create_membership(membership_params, venue, user2)

          membership_params[:end_date] = 2.months.from_now.in_time_zone.strftime("%d/%m/%Y")

          # create overlapping membership
          create_membership(membership_params, venue, user3)
          expect(page).to have_selector(".toast-error")
          page.save_screenshot
          expect(Membership.count).to eq(2)

          # resolve conflict
          expect(page).to have_selector("button", text: I18n.t('.venues.existing_memberships.create_non_overlapping'))
          find("button", text: I18n.t('.venues.existing_memberships.create_non_overlapping')).click
          expect(page).to have_selector(".toast-info")
          expect(Membership.count).to eq(3)
        end
      end
    end
  end

  # creates new membership with existing users by filling the membership form
  def create_membership(membership_params, venue, user)
    expect(page).to have_selector(".tabs-container li a[href='#tab-2']")
    find(".tabs-container li a[href='#tab-2']").click

    within("form") do
      select(venue.courts.second.id, from: "court_ids[]")
      js_script = %Q(document.querySelector('select[name="membership[weekday]"]').value = '#{membership_params[:weekday]}')
      page.execute_script(js_script)

      %i(price start_time end_time start_date end_date).each do |attribute|
        fill_in "membership[#{attribute.to_s}]", with: membership_params[attribute]
      end

      expect(page).to have_selector("select[name='user[user_id]'] option", text: user.email)
      js_script = %Q(document.querySelector('select[name="user[user_id]"]').value = #{user.id})
      page.execute_script(js_script)

      js_script = %Q(document.querySelector('form[action="/memberships"]').submit())
      page.execute_script(js_script)
      sleep(3)
    end
  end
end

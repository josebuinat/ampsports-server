require 'rails_helper'

describe API::ReviewsController do
  render_views

  shared_context "with wrong user" do
    let(:wrong_user) { create(:user) }
    before { sign_in_for_api_with wrong_user }

    it "forbids access for non-authors" do
      is_expected.to have_http_status :unauthorized
      expect(response_json['errors']).to include(I18n.t('api.reviews.unauthorized'))
    end
  end

  let(:venue) { create(:venue) }
  let(:user) { create(:user) }
  let(:response_json) { JSON.parse(response.body) }

  describe "GET index" do
    let!(:reviews) { create_list :review, 2, venue: venue }
    let!(:other_reviews) { create_list :review, 3 }

    context "with venue_id" do
      subject { get :index, venue_id: venue.id }
      it "should return review list for the venue" do
        is_expected.to be_success
        expect(response_json['reviews'].size).to eq 2
      end
    end

    context "without venue_id" do
      it "should throw error" do
        expect(get: :index).not_to be_routable
      end
    end
  end

  describe "POST create" do
    subject { post :create, venue_id: venue.id, review: review_params }
    let(:review_params) { attributes_for :review }

    before { sign_in_for_api_with user }

    it "should create a review for the venue" do
      expect { subject }.to change(Review, :count).by(1)
      expect(response_json['author_id']).to eq(user.id)
      is_expected.to be_success
    end
  end

  describe "POST update" do
    subject { patch :update, venue_id: venue.id, id: review.id, review: review_params }
    let(:review) { create(:review, venue: venue, author: user) }
    let(:review_params) {{ text: "new review", rating: 4.0 }}

    context "with right user" do
      before { sign_in_for_api_with user }

      it "should update the review" do
        is_expected.to be_success
        review.reload
        expect(review.rating).to eq(4.0)
        expect(review.text).to eq("new review")
      end
    end

    include_context "with wrong user"
  end

  describe "POST destroy" do
    subject { delete :destroy, venue_id: venue.id, id: review.id }
    let!(:review) { create(:review, venue: venue, author: user) }

    context "with right user" do
      before { sign_in_for_api_with user }

      it "should delete the review" do
        expect { subject }.to change(Review, :count).by(-1)
        expect { review.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    include_context "with wrong user"
  end
end

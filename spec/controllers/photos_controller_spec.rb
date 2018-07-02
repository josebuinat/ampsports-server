require 'rails_helper'

RSpec.describe PhotosController, type: :controller do
  let(:company) { create :company}
  let(:admin) { create :admin, company: company }
  let(:venue) { create :venue, company: company }
  let(:file) { mock_file_upload('test.jpg', 'image/jpeg') }
  let(:image) { { '0': file } }
  let(:request_params) { { venue_id: venue.id, image: image } }

  before { sign_in admin }

  describe 'POST create' do
    subject { post :create, request_params }

    it { is_expected.to be_success }

    it 'creates a new photo on upload' do
      expect { subject }.to change(Photo, :count).by(1)
    end
  end

  describe 'DELETE destroy' do
    let!(:photo) { create :photo, venue: venue }
    let(:request_params) { { venue_id: venue.id, id: photo.id } }

    subject { delete :destroy, request_params }

    it { is_expected.to be_success }

    it 'deletes a photo' do
      expect { subject }.to change(Photo, :count).by(-1)
    end
  end

  describe 'POST make_primary' do
    let!(:previous_primary) { create :photo, venue: venue }
    let(:photo) { create :photo, venue: venue }
    let(:request_params) { { venue_id: venue.id, photo_id: photo.id } }

    subject { post :make_primary, request_params }

    it { is_expected.to be_success }

    it 'sets venue primary photo' do
      expect { subject }.to change{ venue.reload.primary_photo_id }.to(photo.id)
    end
  end
end

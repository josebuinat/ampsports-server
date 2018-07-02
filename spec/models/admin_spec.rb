require 'rails_helper'

RSpec.describe Admin, type: :model do
  it "works" do
    admin = create(:admin)
    expect(admin).to be_valid
  end

  describe 'email validation' do
    subject { build :admin, email: email }

    context 'with valid email' do
      let(:email) { 'valid@email.com' }

      it { is_expected.to be_valid }
    end

    context 'with invalid email' do
      let(:email) { 'jari.laitamäki@ericsson.com' }

      it { is_expected.to be_invalid }
    end
  end
  it_behaves_like "configurable clock_type" do
    subject { described_class.new }
  end
end

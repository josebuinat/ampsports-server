require 'rails_helper'

describe ApplicationHelper do
  describe 'number_to_currency' do
    let(:subject) { number_to_currency(1) }

    before { @current_company = company }

    context 'when company currency is "USD"' do
      let (:company) { create :usd_company }
      it { is_expected.to eql '$1.00' }
    end

    context 'when company currency is "Euro"' do
      let (:company) { create :euro_company }
      it { is_expected.to eql '€1.00' }
    end

    context 'when company currency is not set' do
      let (:company) { create :company }
      it 'uses dollar as a default ' do
        is_expected.to eql '$1.00'
      end
    end
  end
end

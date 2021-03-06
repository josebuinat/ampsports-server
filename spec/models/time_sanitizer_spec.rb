require 'rails_helper'

describe TimeSanitizer do
  context "add seconds to date of given time ignoring day saiving time change" do
    describe "add_seconds(date, seconds)" do
      it "will ignore time part of given date" do
        result = TimeSanitizer.add_seconds(Time.zone.parse('22/03/2017 23:59:59'), 86400)

        expect(result).to eq Time.zone.parse('23/03/2017 00:00:00')
      end

      it "will point to correct hour on normal day" do
        result = TimeSanitizer.add_seconds(Time.zone.parse('22/03/2017 00:00:00'), 86400)

        expect(result).to eq Time.zone.parse('23/03/2017 00:00:00')
      end

      it "will point to correct hour on +dst day" do
        result = TimeSanitizer.add_seconds(Time.zone.parse('26/03/2017 00:00:00'), 86400)

        expect(result).to eq Time.zone.parse('27/03/2017 00:00:00')
      end

      it "will point to correct hour on -dst day" do
        result = TimeSanitizer.add_seconds(Time.zone.parse('29/10/2017 00:00:00'), 86400)

        expect(result).to eq Time.zone.parse('30/10/2017 00:00:00')
      end
    end
  end

  describe "#time_ceil_at" do
    let(:time) { Time.zone.parse('22/03/2017 10:01:00') }

    it "should return next step time" do
      expect(TimeSanitizer.time_ceil_at(time, 30).to_s(:time)).to eq("10:30")
      expect(TimeSanitizer.time_ceil_at(time, 15).to_s(:time)).to eq("10:15")
    end
  end

  describe '#input' do
    describe 'sanitize date back n forth'
    let(:input) { '10/02/2017' }
    subject { described_class.input(input).to_date }
    it 'returns same date' do
      is_expected.to eq Date.parse(input)
    end
  end
end

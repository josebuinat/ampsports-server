require 'rails_helper'

RSpec.describe Coach::SalaryRate, type: :model do
  let(:company) { create :company }
  let(:venue) { create :venue, :with_users, company: company }
  let(:user) { venue.users.first }
  let(:coach) { create :coach, company: company }

  context 'validations' do
    subject{ salary_rate }
    let(:salary_rate) { build :coach_salary_rate, coach: coach, venue: venue }

    describe "#rate" do
      context "validate presence" do
        it "adds error when absent" do
          salary_rate.rate = nil

          is_expected.not_to be_valid
          expect(subject.errors).to include(:rate)
        end

        it "is valid when present" do
          is_expected.to be_valid
        end
      end
    end

    describe '#presence_of_weekday' do
      it "adds error when absent" do
        salary_rate.monday = false

        is_expected.not_to be_valid
        expect(subject.errors).to include(:weekdays)
      end

      it "is valid when present" do
        is_expected.to be_valid
      end
    end

    describe '#validate_conflicts' do
      subject{ new_salary_rate }

      let!(:salary_rate) do
        create :coach_salary_rate, coach: coach,
                                   venue: venue,
                                   monday: true,
                                   tuesday: true,
                                   wednesday: false
      end
      let(:new_salary_rate) do
        build :coach_salary_rate, coach: coach,
                                  venue: new_salary_rate_venue,
                                  sport_name: new_salary_rate_sport,
                                  start_time: new_salary_rate_start,
                                  end_time: new_salary_rate_end,
                                  monday: false,
                                  tuesday: on_tuesday,
                                  wednesday: true
      end
      let(:new_salary_rate_sport) { 'tennis' }
      let(:new_salary_rate_venue) { venue }
      let(:new_salary_rate_start) { salary_rate.start_time }
      let(:new_salary_rate_end) { salary_rate.end_time }
      let(:on_tuesday) { true }

      context 'with overlapping time' do
        context 'with other venue' do
          let(:new_salary_rate_venue) { create :venue }

          it { is_expected.to be_valid }
        end

        context 'with other sport' do
          let(:new_salary_rate_sport) { 'squash' }

          it { is_expected.to be_valid }
        end

        context 'with not interferring weekdays' do
          let(:on_tuesday) { false }

          it { is_expected.to be_valid }
        end

        context 'with matching time' do
          it 'adds error and conflicts' do
            is_expected.not_to be_valid
            expect(subject.errors.messages).to include(
              start_time: ["overlapping with other salary rates"],
              conflicts: [["01/01/2000 12:00 - 01/01/2000 13:00"]])
          end
        end

        context 'with overlapped start' do
          let(:new_salary_rate_start) { salary_rate.end_time - 1.minutes }
          let(:new_salary_rate_end) { salary_rate.end_time + 59.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'with overlapped end' do
          let(:new_salary_rate_start) { salary_rate.start_time - 59.minutes }
          let(:new_salary_rate_end) { salary_rate.start_time + 1.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'when wrapped by longer salary rate' do
          let(:new_salary_rate_start) { salary_rate.start_time + 10.minutes }
          let(:new_salary_rate_end) { salary_rate.end_time - 10.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'when wrapping shorter salary rate' do
          let(:new_salary_rate_start) { salary_rate.start_time - 10.minutes }
          let(:new_salary_rate_end) { salary_rate.end_time + 10.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end
      end

      context 'with not overlapping time' do
        context 'with earlier salary rate' do
          let(:new_salary_rate_start) { salary_rate.end_time + 1.minutes }
          let(:new_salary_rate_end) { salary_rate.end_time + 61.minutes }

          it { is_expected.to be_valid }
        end

        context 'with later salary rate' do
          let(:new_salary_rate_start) { salary_rate.start_time - 61.minutes }
          let(:new_salary_rate_end) { salary_rate.start_time - 1.minutes }

          it { is_expected.to be_valid }
        end
      end

      context 'with back-to-back time' do
        context 'when after' do
          let(:new_salary_rate_start) { salary_rate.end_time }
          let(:new_salary_rate_end) { salary_rate.end_time + 60.minutes }

          it { is_expected.to be_valid }
        end

        context 'when before' do
          let(:new_salary_rate_start) { salary_rate.start_time - 60.minutes }
          let(:new_salary_rate_end) { salary_rate.start_time }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end

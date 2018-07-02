require 'rails_helper'

describe Admin::Venues::CoachesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  let(:venue) { create :venue, :with_courts, company: company, court_counts: 1 }
  before { sign_in_for_api_with current_admin }

  describe 'GET #available_select_options' do
    subject { get :available_select_options, venue_id: venue.id, **params }

    let!(:coach) { create :coach, company: company, level: :manager }
    let!(:unavailable_coach) { create :coach, company: company, level: :manager }
    let!(:unrelated_coach) { create :coach, :with_company, level: :manager }
    let(:unrelated_venue) { create :venue, company: unrelated_coach.company }
    let!(:price_rate) do
      create :coach_price_rate, start_time: start_time,
                                end_time: start_time.advance(days: 1),
                                coach: coach, venue: venue,
                                sport_name: sport
    end
    let!(:unavailable_price_rate) do
      create :coach_price_rate, start_time: start_time,
                                end_time: start_time.advance(hours: 1),
                                coach: unavailable_coach, venue: venue,
                                sport_name: sport
    end
    let!(:unrelated_price_rate) do
      create :coach_price_rate, start_time: start_time,
                                end_time: start_time.advance(days: 1),
                                coach: unrelated_coach, venue: unrelated_venue,
                                sport_name: sport
    end
    let(:start_time) { in_venue_tz{ Time.current.advance(days: 1).at_noon } }
    let(:end_time) { start_time.advance(hours: 3) }
    let(:court) { venue.courts.first }
    let(:sport) { court.sport_name }
    let(:params) do
      {
        court_id: court.id,
        start_time: start_time.to_s(:date_time),
        end_time: end_time.to_s(:date_time)
      }
    end

    let(:coach_ids) { json.map { |x| x['value'] } }

    it 'renders all available coachs' do
      is_expected.to be_success
      expect(coach_ids).to match_array [coach.id]
    end
  end
end

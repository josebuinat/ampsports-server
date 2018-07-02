require 'rails_helper'

shared_examples 'not applicable game pass' do
  it "does not return game pass" do
    is_expected.to be_success
    expect(game_pass_ids).to match []
  end
end

shared_examples 'applicable game pass' do
  it 'returns game pass' do
    is_expected.to be_success
    expect(game_pass_ids).to match [game_pass.id]
  end
end

describe API::GamePassesController, type: :controller do
  render_views
  let!(:current_user) { create :user }
  let(:body) { JSON.parse(response.body) }
  let!(:venue) { create :venue, users: [current_user] }

  before { sign_in_for_api_with(current_user) }

  describe '#available' do
    subject { get :available, params }

    let(:game_pass_ids) { body.to_a.map { |x| x['value'] } }

    let!(:next_monday) do
      Time.use_zone(venue.timezone) do
        Time.current.beginning_of_week.advance(weeks: 1)
      end
    end
    let(:start_time) { next_monday.change(hour: 12) }
    let(:end_time) { start_time + 60.minutes }
    let(:duration) { }
    let!(:court) {
      create :court,  venue: venue,
                      indoor: false,
                      sport_name: Court.sport_names[:golf],
                      surface: Court.surfaces[:red_clay]
    }
    let(:coach_ids) { [] }
    let(:params) do
      {
        start_time: start_time,
        end_time: end_time,
        duration: duration,
        court_id: court.id,
        coach_ids: coach_ids,
      }
    end

    let(:available_game_pass_values) do
      {
        venue: venue,
        user: current_user,
        active: true,
        is_paid: true,
        remaining_charges: 10,
        total_charges: 10,
        court_type: GamePass.court_types[:outdoor],
        court_sports: ['golf'],
        court_surfaces: ['red_clay'],
        start_date: next_monday - 1.days,
        end_date: next_monday + 1.days,
        time_limitations: [{ from: '11:30', to: '13:30', weekdays: ['mon'] }]
      }
    end

    context "when available game_pass" do
      let!(:game_pass) { create :game_pass, available_game_pass_values }

      context "when start_time and end_time were set" do
        it_behaves_like "applicable game pass"
      end

      context "when start_time and duration were set" do
        let(:duration) { 60 }
        let(:end_time) { nil }

        it_behaves_like "applicable game pass"
      end
    end

    context "when unavailable game_pass" do
      context "when inactive" do

        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(active: false, total_charges: 0) }

        it_behaves_like "not applicable game pass"
      end

      context "when all charges were spent" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(remaining_charges: 0.9) }

        it_behaves_like "not applicable game pass"
      end
    end

    context "when court limitations are set" do
      context "when game pass and court have different court type" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_type: GamePass.court_types[:indoor]) }

        it_behaves_like "not applicable game pass"
      end

      context "when applies to any court type" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_type: GamePass.court_types[:any]) }

        it_behaves_like "applicable game pass"
      end

      context "when game pass and court have same court type" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_type: GamePass.court_types[:outdoor]) }

        it_behaves_like "applicable game pass"
      end

      context "when game pass and court have different court sport" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_sports: ['tennis']) }

        it_behaves_like "not applicable game pass"
      end

      context "when applies to any court sport" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_sports: []) }

        it_behaves_like "applicable game pass"
      end

      context "when game pass and court have same court sport" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_sports: ['golf']) }

        it_behaves_like "applicable game pass"
      end

      context "when game pass and court have different court surface" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_surfaces: ['grass']) }

        it_behaves_like "not applicable game pass"
      end

      context "when applies to any court surface" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_surfaces: []) }

        it_behaves_like "applicable game pass"
      end

      context "when game pass and court have same court surface" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(court_surfaces: ['red_clay']) }

        it_behaves_like "applicable game pass"
      end
    end

    context "when date limitations are set" do
      context "when any start_date" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(start_date: nil) }

        it_behaves_like "applicable game pass"
      end

      context "when start_date is earlier than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(start_date: next_monday - 1.days) }

        it_behaves_like "applicable game pass"
      end

      context "when start_date matches searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(start_date: next_monday) }

        it_behaves_like "applicable game pass"
      end

      context "when start_date is later than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(start_date: next_monday + 1.days) }

        it_behaves_like "not applicable game pass"
      end

      context "when applies to any end_date" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(start_date: nil) }

        it_behaves_like "applicable game pass"
      end

      context "when end_date is later than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(end_date: next_monday + 1.days) }

        it_behaves_like "applicable game pass"
      end

      context "when end_date matches searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(end_date: next_monday) }

        it_behaves_like "applicable game pass"
      end

      context "when end_date is earlier than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(end_date: next_monday - 1.days) }

        it_behaves_like "not applicable game pass"
      end
    end
    # search for 12:00-13:00 wed
    context "when time limitations are set" do
      context "when no limitations" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: []) }

        it_behaves_like "applicable game pass"
      end

      context "when applies to any weekday" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: [] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when weekday matches searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when different weekday than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: ['tue'] }]) }

        it_behaves_like "not applicable game pass"
      end

      context "when 'from' time is earlier than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:59',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when 'from' time matches searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '12:00',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when 'from' time is later than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '12:01',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "not applicable game pass"
      end

      context "when 'to' time is later than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:01',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when 'to' time matches searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:00',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable game pass"
      end

      context "when 'to' time is earlier than searched" do
        let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '12:59',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "not applicable game pass"
      end
    end

    context 'whit coach limitations' do
      let(:coach_ids) { [coach.id] }
      let(:coach) { create :coach }
      let(:other_coach) { create :coach }
      let!(:game_pass) { create :game_pass, available_game_pass_values.
                                                merge(coach_ids: gamepass_coach_ids) }
      context 'when game pass for any coach' do
        let(:gamepass_coach_ids) { [] }
        it_behaves_like "applicable game pass"
      end

      context 'when game pass for a coach but coach not searched' do
        let(:coach_ids) { [] }
        let(:gamepass_coach_ids) { [coach.id] }
        it_behaves_like "not applicable game pass"
      end

      context 'when game pass includes same coach as searched' do
        let(:gamepass_coach_ids) { [coach.id] }
        it_behaves_like "applicable game pass"
      end

      context 'when game pass includes only other coach' do
        let(:gamepass_coach_ids) { [other_coach.id] }
        it_behaves_like "not applicable game pass"
      end

      context 'when game pass includes more coaches' do
        let(:gamepass_coach_ids) { [coach.id, other_coach.id] }
        it_behaves_like "applicable game pass"
      end

      context 'when game pass includes both searched coaches' do
        let(:coach_ids) { [other_coach.id, coach.id] }
        let(:gamepass_coach_ids) { [coach.id, other_coach.id] }
        it_behaves_like "applicable game pass"
      end

      context 'when game pass includes only one of searched coaches' do
        let(:coach_ids) { [coach.id, other_coach.id] }
        let(:gamepass_coach_ids) { [other_coach.id] }
        it_behaves_like "not applicable game pass"
      end
    end
  end
end

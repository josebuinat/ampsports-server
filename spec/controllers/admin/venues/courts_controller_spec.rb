require 'rails_helper'

shared_examples 'not applicable discount' do
  it 'does not apply discount' do
    is_expected.to be_success
    expect(body['prices']).to eq [price]
  end
end

shared_examples 'applicable discount' do
  it 'applies discount' do
    is_expected.to be_success
    expect(body['prices']).to eq [discount.apply(price)]
  end
end

describe Admin::Venues::CourtsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }
  let!(:venue) { create :venue, company: company }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }
    let(:body) { JSON.parse response.body }
    let(:court_ids) { body['courts'].map { |x| x['id'] } }
    let!(:my_court) { create :court, venue: venue }
    let!(:not_my_court) { create :court }

    it 'works' do
      is_expected.to be_success
      expect(court_ids).to eq [my_court.id]
    end

    context 'with coach admin' do
      let(:current_admin) { create :coach, company: company, level: :manager }

      it 'works' do
        is_expected.to be_success
        expect(court_ids).to eq [my_court.id]
      end
    end
  end

  describe '#show' do
    subject { get :show, format: :json, venue_id: venue.id, id: court.id }
    let!(:court) { create :court, venue: venue }
    it { is_expected.to be_success }
  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: court.id, court: params }
    let!(:shared_court) { create :court, venue: venue }
    let!(:court) { create :court, venue: venue, shared_courts: [shared_court] }
    let(:params) { { shared_court_ids: [] } }

    it 'works' do
      expect { subject }.to change { court.reload.shared_courts.reload }.to([])
      is_expected.to be_success
    end
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, court: params, create_copies_count: create_copies_count }
    let(:create_copies_count) { nil }

    context 'with valid params' do
      let(:params) { attributes_for(:court) }
      it 'works' do
        expect { subject }.to change { venue.courts.count }.by(1)
        is_expected.to be_created
      end

      context 'when create copies is specified' do
        let(:params) { attributes_for(:court).merge(index: 6) }
        let(:create_copies_count) { 2 }
        it 'creates copies with consecutive indexes' do
          expect { subject }.to change { venue.courts.count }.by(3)
          is_expected.to be_created
          expect(venue.courts.map(&:index)).to match_array [6,7,8]
        end
      end
    end

    context 'with invalid params' do
      let(:params) { { index: 5, sport_name: 'tennis' } }
      it 'does not work' do
        expect { subject }.not_to change { venue.courts.count }
        is_expected.to be_unprocessable
      end

      context 'when create copies is specified' do
        let(:create_copies_count) { 2 }
        it 'works' do
          expect { subject }.not_to change { venue.courts.count }
          is_expected.to be_unprocessable
        end
      end
    end
  end

  describe '#prices_at' do
    subject { post :prices_at, params }

    let(:body) { JSON.parse response.body }
    let!(:next_monday) do
      Time.use_zone(venue.timezone) do
        Time.current.beginning_of_week.advance(weeks: 1)
      end
    end
    let(:start_time) { next_monday.change(hour: 12) }
    let(:end_time) { start_time + 60.minutes }
    let!(:user) { create :user, venues: [venue] }
    let!(:court) {
      create :court, :with_prices,
                      venue: venue,
                      indoor: false,
                      sport_name: Court.sport_names[:golf],
                      surface: Court.surfaces[:red_clay]
    }
    let(:price) { court.price_at(start_time, end_time, nil) }
    let(:params) do
      {
        venue_id: venue.id,
        user_id: user.id,
        reservations: [
          {
            start_tact: start_time.to_s(:tine),
            end_tact: end_time.to_s(:time),
            date: start_time.to_s(:date),
            court_id: court.id,
          }
        ]
      }
    end

    let(:available_discount_values) do
      {
        venue: venue,
        users: [user],
        court_type: GamePass.court_types[:outdoor],
        court_sports: ['golf'],
        court_surfaces: ['red_clay'],
        start_date: next_monday - 1.days,
        end_date: next_monday + 1.days,
        time_limitations: [{ from: '11:30', to: '13:30', weekdays: ['mon'] }]
      }
    end

    context "when all limitations were set" do
      let!(:discount) { create :discount, available_discount_values }

      context "when start_time and duration were set" do
        it_behaves_like "applicable discount"
      end
    end

    context "when court limitations were set" do
      context "when discount and court have different court type" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_type: GamePass.court_types[:indoor]) }

        it_behaves_like "not applicable discount"
      end

      context "when applies to any court type" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_type: GamePass.court_types[:any]) }

        it_behaves_like "applicable discount"
      end

      context "when discount and court have same court type" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_type: GamePass.court_types[:outdoor]) }

        it_behaves_like "applicable discount"
      end

      context "when discount and court have different court sport" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_sports: ['tennis']) }

        it_behaves_like "not applicable discount"
      end

      context "when applies to any court sport" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_sports: []) }

        it_behaves_like "applicable discount"
      end

      context "when discount and court have same court sport" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_sports: ['golf']) }

        it_behaves_like "applicable discount"
      end

      context "when discount and court have different court surface" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_surfaces: ['grass']) }

        it_behaves_like "not applicable discount"
      end

      context "when applies to any court surface" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_surfaces: []) }

        it_behaves_like "applicable discount"
      end

      context "when discount and court have same court surface" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(court_surfaces: ['red_clay']) }

        it_behaves_like "applicable discount"
      end
    end

    context "when date limitations are set" do
      context "when any start_date" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(start_date: nil) }

        it_behaves_like "applicable discount"
      end

      context "when start_date is earlier than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(start_date: next_monday - 1.days) }

        it_behaves_like "applicable discount"
      end

      context "when start_date matches searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(start_date: next_monday) }

        it_behaves_like "applicable discount"
      end

      context "when start_date is later than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(start_date: next_monday + 1.days) }

        it_behaves_like "not applicable discount"
      end

      context "when applies to any end_date" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(start_date: nil) }

        it_behaves_like "applicable discount"
      end

      context "when end_date is later than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(end_date: next_monday + 1.days) }

        it_behaves_like "applicable discount"
      end

      context "when end_date matches searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(end_date: next_monday) }

        it_behaves_like "applicable discount"
      end

      context "when end_date is earlier than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(end_date: next_monday - 1.days) }

        it_behaves_like "not applicable discount"
      end
    end
    # search for 12:00-13:00 wed
    context "when time limitations are set" do
      context "when has no time limitations" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: []) }

        it_behaves_like "applicable discount"
      end

      context "when applies to any weekday" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: [] }]) }

        it_behaves_like "applicable discount"
      end

      context "when same weekday as searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable discount"
      end

      context "when different weekday than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:30',
                                                                           weekdays: ['tue'] }]) }

        it_behaves_like "not applicable discount"
      end

      context "when 'from' time is earlier than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:59',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable discount"
      end

      context "when 'from' time matches searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '12:00',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable discount"
      end

      context "when 'from' time is later than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '12:01',
                                                                           to: '13:30',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "not applicable discount"
      end

      context "when 'to' time is later than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:01',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable discount"
      end

      context "when 'to' time matches searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '13:00',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "applicable discount"
      end

      context "when 'to' time is earlier than searched" do
        let!(:discount) { create :discount, available_discount_values.
                                                merge(time_limitations: [{ from: '11:30',
                                                                           to: '12:59',
                                                                           weekdays: ['mon'] }]) }

        it_behaves_like "not applicable discount"
      end
    end
  end

  describe '#available_select_options' do
    subject{ get :available_select_options, venue_id: venue.id, **params }

    let(:params) do
      {
        start_time: start_time.to_s(:date_time),
        end_time: start_time.advance(minutes: 60).to_s(:date_time)
      }
    end
    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }
    let!(:court1) { create :court, :with_prices, venue: venue }
    let!(:court2) { create :court, :with_prices, venue: venue }
    let!(:reservation1) { create :reservation, court: court1, start_time: start_time }

    let(:court_ids) { json.map { |x| x['value'] } }

    it 'returns available courts' do
      is_expected.to be_success

      expect(court_ids).to eq [court2.id]
    end
  end

  describe 'GET #calendar_print' do
    let(:today) { Time.current.advance(weeks: 2).beginning_of_week.at_noon }
    let(:c_date) { today.strftime("%d/%m/%Y") }
    let(:admin) { create :admin, :with_company }
    let(:company) { admin.company }
    let(:venue) { create :venue, :with_courts, court_count: 12, company: company }
    let(:first_court) { venue.courts.first }
    let(:user) {create :user, first_name: "<b>Jä{r\\vi</b"}
    let!(:existing_reservation) { create :reservation, :two_hours, court: first_court, user: user }

    subject { get :calendar_print, venue_id: venue.id, calendar_date: c_date, format: :pdf, auth_token: "SECRETTOKEN" }
    it { is_expected.to be_success }

    it "renders the correct latex template" do
      expect(response).to be_successful
      expect(subject).to render_template("calendar_print")

      page_analysis = PDF::Inspector::Page.analyze(response.body)
      text_analysis = PDF::Inspector::Text.analyze(response.body)
      expect(page_analysis.pages.size).to eq 2
      expect(text_analysis.strings).to include first_court.court_name.delete(' ')
      # Note that strings returns an array containing one string for each text drawing operation in the PDF.
      reservation_title = ActionController::Base.helpers.strip_tags(existing_reservation.reservation_title)
      expect(text_analysis.strings.join('')).to include reservation_title.gsub(/[[:punct:]]/,'').delete(' ')
      title = venue.venue_name + today.strftime("%A, %B %-d")
      expect(text_analysis.strings).to include title.delete(' ')

    end

  end

end

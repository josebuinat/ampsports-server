shared_examples "set_venue" do
  it "should assign @venue" do
    expect(assigns(:venue)).to eq venue
  end
end


shared_examples "update membership" do
  it "should redirect to memberships_path(venue)" do
    expect(response).to redirect_to(memberships_path(venue))
  end

  it "should set success message" do
    expect(flash[:notice]).to be_present
  end

  it "should not create new membership" do
    expect(Membership.count).to eq(1)
  end

  it "should update membership attributes" do
    membership.reload
    membership_attrs = params_hash[:membership]

    expected_start_time = expected_end_time = nil
    in_venue_tz do
      expected_start_time = Time.zone.parse(membership_attrs[:start_date] + " " + membership_attrs[:start_time]).utc
      expected_end_time = Time.zone.parse(membership_attrs[:end_date] + " " + membership_attrs[:end_time]).utc
    end

    expect(membership.start_time).to eq expected_start_time
    expect(membership.end_time).to eq expected_end_time
    expect(membership.price).to eq(membership_attrs[:price])
  end

  it "should update the reservations" do
    membership_attrs = params_hash[:membership]
    time_params = in_venue_tz do
      {
        start_time: Time.zone.parse(membership_attrs[:start_date] + " " + membership_attrs[:start_time]).utc,
        end_time: Time.zone.parse(membership_attrs[:start_date] + " " + membership_attrs[:end_time]).utc,
        membership_start_time: Time.zone.parse(membership_attrs[:start_date] + " " + membership_attrs[:start_time]).utc,
        membership_end_time: Time.zone.parse(membership_attrs[:end_date] + " " + membership_attrs[:end_time]).utc
      }
    end
    reservation_count = calculate_number_of_reservations(time_params, court)
    expect(membership.reservations.count).to eq reservation_count
    expect(membership.reservations.first.court.id).to eq(params_hash[:court_ids][0])
  end
end

def calculate_number_of_reservations(time_params, court)
  venue = court.venue
  time_params = time_params.dup
  count = 0

  Time.use_zone(venue.timezone) do
    while (time_params[:start_time].to_date <= time_params[:membership_end_time])
      if reservable?(time_params, court)
        count += 1
      end
      time_params[:start_time] = time_params[:start_time].in_time_zone.advance(weeks: 1)
      time_params[:end_time] = time_params[:end_time].in_time_zone.advance(weeks: 1)
    end
  end
  count
end

def reservable?(time_params, court)
  booking_duration = (time_params[:end_time] - time_params[:start_time]) * 24 * 60 # in minutes
  min_duration = Court.duration_policies[court.duration_policy]
  valid_duration = (booking_duration >= min_duration) && (booking_duration % min_duration == 0)

  valid_duration &&
    time_params[:start_time] >= court.created_at &&
    time_params[:start_time] >= time_params[:membership_start_time] &&
    court.working?(time_params[:start_time], time_params[:end_time])
end

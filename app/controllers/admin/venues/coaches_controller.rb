class Admin::Venues::CoachesController < Admin::BaseController
  around_action :use_timezone

  def available_select_options
    start_times = [*params[:start_time]]
    end_times = [*params[:end_time]]
    include_coach_ids = params[:include_coach_ids].to_a.map(&:to_i)

    available_coaches_per_reservation = [*params[:court_id]].map.with_index do |court_id, index|
      court = venue.courts.find(court_id)
      start_time = TimeSanitizer.output_input(start_times[index])
      end_time = TimeSanitizer.output_input(end_times[index])

      authorized_scope(company.coaches).
        with_prices_for(court, start_time, end_time).
        select { |coach| include_coach_ids.include?(coach.id) || coach.available?(court, start_time, end_time) }
    end

    available_coaches = available_coaches_per_reservation.inject(:&).map do |coach|
      { value: coach.id, label: coach.full_name }
    end

    render json: available_coaches
  end

  private


  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def company
    @company ||= current_admin.company
  end
end

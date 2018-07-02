class VenuePolicy < ApplicationPolicy
  class Scope < Scope
    def can_read_related?
      user.can?(:courts, :read) ||
        user.can?(:prices, :read) ||
        user.can?(:holidays, :read)
    end

    def index
      # everyone need to see the venues on the left
      # example of implementation if venues are accessible only with permission:
      # user.can?(:venues, :read) || (user.can?(:profile_coach_calendar, :read) && user.coach?)
      scope
    end

    def show
      if user.can?(:venues, :read) ||
          can_read_related? ||
          user.can?(:email_customization, :read) ||
          user.can?(:colors, :read)
        scope
      else
        scope.none
      end
    end

    def closing_hours
      if user.can?(:venues, :read) ||
            can_read_related? ||
            user.can?(:calendar, :read) ||
            (user.can?(:profile_coach_calendar, :read) && user.coach?)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:venues, :edit) ||
          user.can?(:email_customization, :edit) ||
          user.can?(:colors, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy
      if user.can?(:venues, :edit)
        scope
      else
        scope.none
      end
    end

    def select_options_for_court_sports
      if user.can?(:venues, :read) ||
          user.can?(:courts, :read) ||
          user.can?(:calendar, :read) ||
          user.can?(:discounts, :edit) ||
          user.can?(:game_passes, :edit) ||
          (user.can?(:profile_coach_calendar, :read) && user.coach?)
        scope
      else
        scope.none
      end
    end

    def select_options_for_court_surfaces
      select_options_for_court_sports
    end

    def weather
      if user.can?(:venues, :read) || user.can?(:dashboard, :read)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:venues, :edit)
  end

  def permitted_attributes
    ordinary_attributes = %i(venue_name description parking_info transit_info status
      booking_ahead_limit latitude longitude street city zip phone_number website timezone
      primary_photo_id registration_confirmation_message confirmation_message cancellation_time
      max_consecutive_bookable_hours max_bookable_hours_per_day invoice_fee allow_overlapping_resell)

    email_customization_attributes = %i(registration_confirmation_message confirmation_message)
    ordinary_nested_attributes = {
      photos_attributes: [:id, :image, :_destroy, :primary],
    }

    colors = %w(user discount classification group coach)
    colors_scalar_attributes = colors.map { |color| "#{color}_colors".to_sym }
    colors_nested_attributes = colors.inject({}) do |sum, name|
      sum.merge({
        "#{name}_colors".to_sym => ["#{name}_id".to_sym, :color]
      })
    end

    colors_nested_attributes.merge!(custom_colors: Venue::DEFAULT_COLORS.keys)

    if user.can?(:venues, :edit)
      return ordinary_attributes + colors_scalar_attributes +
        [ ordinary_nested_attributes.merge(colors_nested_attributes) ]
    end

    # We can't use bunch of ifs here, because if use can customize email AND customize colors
    # then we need to return permitted attributes for both emails AND colors

    edit_rules_grid = {
      email_customization: email_customization_attributes,
      colors: colors_scalar_attributes + [colors_nested_attributes]
    }
    edit_rules_grid.keys.inject([]) do |sum, permission|
      user.can?(permission, :edit) ? sum + edit_rules_grid[permission] : sum
    end.sort do |x, y|
      # because we will splat permission later to strong params .permit! we must ensure
      # that hash goes as a last element
      x.is_a?(Hash) ? 1 : 0
    end
    # Also, please consider merging the most right elements of this array if they are hashes
    # (it's impossible right now, but in case you'll add more nested attributes don't forget about it!)
  end

  def permitted_business_hours
    user.can?(:venues, :edit)
  end

  def permitted_settings
    if user.can?(:venues, :edit)
      [settings: Venue.settings_config.map { |scope, schema| [scope => schema.keys ] }]
    else
      []
    end
  end
end

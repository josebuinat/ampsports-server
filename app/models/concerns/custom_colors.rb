# manages custom_colors field
module CustomColors
  extend ActiveSupport::Concern

  included do
    DEFAULT_COLORS = {
      unpaid: '#f44336',
      paid: '#4caf50',
      semi_paid: '#f8ac59',
      membership_paid: '#4caf50',
      membership_unpaid: '#f44336',
      membership_semi_paid: '#f8ac59',
      reselling: nil,
      invoiced: nil,
      other: '#eeeeee',
      guest_unpaid: nil,
      guest_paid: nil,
      guest_semi_paid: nil,
      coached: nil,
      online_booking: nil,
    }.freeze

    store :custom_colors, coder: Hash

    # user_colors {user_id: color}
    store :user_colors, coder: Hash

    # discount_colors {discount_id: color}
    store :discount_colors, coder: Hash

    # classification_colors {classification_id: color}
    store :classification_colors, coder: Hash

    # group_colors {group_id: color}
    store :group_colors, coder: Hash

    # coach_colors {coach_id: color}
    store :coach_colors, coder: Hash

    def custom_colors
      DEFAULT_COLORS.map do |type, default_color|
        custom_color = self[:custom_colors][type]
        [type, custom_color.blank? ? default_color : custom_color]
      end.to_h
    end

    def custom_colors=(colors)
      colors.to_h.each do |type, color|
        type = type.to_s.strip.to_sym

        if DEFAULT_COLORS.keys.include?(type)
          color = color.to_s.strip
          # reset to nil
          self[:custom_colors][type] = color.blank? ? nil : color
        end
      end

      self[:custom_colors]
    end

    %w(user_colors discount_colors classification_colors group_colors coach_colors).each do |colors_type|
      define_method("#{colors_type}=") do |colors_array|
        self[colors_type] = {}
        colors_array.to_a.each do |color_object|
          color_object = color_object[1] if color_object.is_a? Array
          color = color_object[:color].to_s.strip
          # e.g. user_id, discount_id etc
          relation_id_name = (colors_type.split('_colors')[0] + '_id').to_sym
          relation_id = color_object[relation_id_name].to_i

          self[colors_type.to_sym][relation_id] = color if relation_id > 0
        end
      end

      define_method(colors_type) do
        self[colors_type.to_sym].to_a.map do |relation_id, color|
          relation_id_name = (colors_type.split('_colors')[0] + '_id').to_sym
          { relation_id_name => relation_id, color: color } if color.present?
        end.compact
      end

      # skip customly defined methods
      unless %w(user_colors discount_colors).include?(colors_type)
        define_method("get_#{colors_type.chop}") do |id|
          self[colors_type.to_sym][id]
        end
      end
    end

    def get_user_color(user)
      return unless user.is_a? User

      color = self[:user_colors][user.id]
      if color.blank?
        color = get_discount_colors(user.discounts).first
      end
      color
    end

    def get_discount_colors(discounts)
      discounts.map do |discount|
        self[:discount_colors][discount.id]
      end
    end
  end
end

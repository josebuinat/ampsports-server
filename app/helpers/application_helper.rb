module ApplicationHelper
  def current_timezone
    current_user.try(:tz) || Time.zone
  end

  def is_active_controller(controller_name)
      params[:controller] == controller_name ? "active" : nil
  end

  def is_active_action(action_name)
      params[:action] == action_name ? "active" : nil
  end

  def avatar_url(user)
    gravatar_id = Digest::MD5::hexdigest(user.email).downcase
    if user.image
      user.image
    else
      "http://a1.mzstatic.com/us/r30/Purple49/v4/17/10/37/1710377b-de94-d86f-dbdd-b7b47b3bf41a/icon175x175.jpeg"
    end
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def t_enum(model, enum, key)
    I18n.t("activerecord.attributes.#{model.to_s.downcase}.#{enum.to_s}.#{key}")
  end

  # returns integer value by taking into account 2 decimal places
  # required since footable data-type=number removes trailing decimal zeros and other formatting from td
  def footable_sort_value(num)
    (num * 100).to_i
  end

  def number_to_currency(number, options ={})
    if @current_company
      unit = @current_company.currency_unit
      options[:unit] = unit unless options[:unit]
    end
    super
  end

end

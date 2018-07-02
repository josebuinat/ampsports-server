# email related actions
class EmailListsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_venue, only: [:index, :show, :create, :search, :custom_mail]

  def index
    @email_lists = @venue.email_lists
    respond_to do |format|
      format.html { render partial: "email_lists/index" }
      format.json { render json: @email_lists.as_json }
    end
  end

  def show
    @email_list = EmailList.find(params[:id])
    render partial: "email_lists/email_list"
  end

  def create
    @email_list = @venue.email_lists.new(email_list_params)
    if @email_list.save
      render json: {
        email_list: @email_list,
        message: "Email list '#{@email_list.name}' List created."
      }
    else
      render json: { errors: @email_list.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def update
    @email_list = EmailList.find(params[:id])
    if @email_list.update_attributes(email_list_params)
      render json: {
        email_list: @email_list,
        message: t('.success')
      }
    else
      render json: { errors: @email_list.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def remove_users
    @email_list = EmailList.find(params[:email_list_id])
    @email_list.users.delete(*params[:users])
    render json: {'message': t('.success')}
  end

  # List of venue users not in the email list
  def off_list_users
    @email_list = EmailList.find(params[:email_list_id])

    render_users(@email_list.off_list_users.subscription_enabled)
  end

  def listed_users
    @email_list = EmailList.find(params[:email_list_id])

    render_users(@email_list.users)
  end

  def render_users(users_scope)
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
    users = users_scope.search(params[:search]).order(sort_params).page(params[:page]).per_page(per_page)
    user_fields = [:id, :first_name, :last_name, :email, :phone_number, :city, :street_address, :zipcode]

    render json: {
      users: users.map { |user| user.as_json(only: user_fields) },
      current_page: users.current_page,
      total_pages: users.total_pages
    }
  end

  def add_users
    @email_list = EmailList.find(params[:email_list_id])
    if(params[:add_all])
      @email_list.add_all_users
    else
      @email_list.add_users(params[:users])
    end
    render json: { 'message': t('.success') }
  end

  def destroy
    @email_list = EmailList.find(params[:id])
    render json: {
      'email_list': @email_list.destroy,
      'message': t('.success')
    }
  end

  def custom_mail
    mail_params = custom_mail_params
    _custom_mail = CustomMail.build_custom_mail(mail_params, @venue.id)

    if _custom_mail.recipient_emails.blank?
      respond_to do |format|
        format.js do
          render json: {errors: t('.no_recipient')},
            status: :unprocessable_entity
        end
      end
    else
      _custom_mail.save
      _custom_mail.send_mail
      # TODO separate controller action for sending test mail
      _custom_mail.send_test_mail(current_admin.email) if mail_params[:send_copy]
      respond_to do |format|
        format.js { render json: {message: t('.success')} }
      end
    end
  end

  private

  def email_list_params
    params.require(:email_list).permit(:name)
  end

  def custom_mail_params
    params[:custom_mail] = JSON.parse(params[:custom_mail])
    mail_params = params.require(:custom_mail).permit(:body, :subject, :from, :send_copy, :to_users, :to_groups => [])
    mail_params[:to_users] = mail_params[:to_users].split(',').map(&:strip)
    mail_params[:image] = params[:image]
    mail_params
  end

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end

  # returns hash {column_name: 'asc'}
  # params = {sort_by: '', sort_order: 'asc or desc'}
  def sort_params
    columns = case params[:sort_by]
      when 'full_name'
        [:first_name, :last_name]
      when 'email'
        [:email]
      when 'phone_number'
        [:phone_number]
      when 'address'
        [:city, :street_address]
      else
        [:created_at]
    end
    order = params[:sort_order].present? ? params[:sort_order] : 'asc'
    columns.product([order]).to_h
  end
end

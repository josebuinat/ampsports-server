class Admin::Venues::Emails::Lists::UsersController < Admin::BaseController
  def index
    @users = list.users.search(params[:search])
    @users = @users.sort_on(params[:sort_on], venue: venue) if params[:sort_on]
    @users = @users.paginate(page: params[:page], per_page: per_page)
  end

  def not_listed
    @users = list.off_list_users.
                  search(params[:search]).
                  select("users.*, venue_user_connectors.email_subscription")
    @users = @users.sort_on(params[:sort_on], venue: venue) if params[:sort_on]
    @users = @users.paginate(page: params[:page], per_page: per_page)
    render 'index'
  end

  def add_many
    if params[:add_all]
      list.add_all_users
    else
      list.add_users(params[:user_ids])
    end

    @users = list.users.paginate(page: 1, per_page: per_page)
    render 'index'
  end

  def remove_many
    email_list_connector = list.email_list_user_connectors.where(user_id: params[:user_ids])
    email_list_connector.find_each(&:destroy)

    @users = list.users.paginate(page: 1, per_page: per_page)
    render 'index'
  end

  protected

  def list
    @list ||= authorized_scope(venue.email_lists).find(params[:list_id])
  end

  def venue
    @venue ||= current_admin.company.venues.find(params[:venue_id])
  end

  def per_page
    params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
  end
end

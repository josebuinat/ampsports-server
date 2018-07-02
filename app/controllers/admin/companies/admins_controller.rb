class Admin::Companies::AdminsController < Admin::BaseController
  def index
    @admins = authorized_scope(company.admins)
    @admins = @admins.search(params[:search]) if params[:search].present?
    @admins = @admins.sort_on(params[:sort_on]) if params[:sort_on].present?
    @admins = @admins.paginate(page: params[:page], per_page: 5)
  end

  def show
    admin
  end

  def create
    @admin = authorize company.admins.build(create_params)

    if @admin.save
      render 'show', status: :created
    else
      render json: { errors: @admin.errors }, status: :unprocessable_entity
    end
  end

  def update
    if admin.update(update_params)
      passport_files = params.dig(:admin, :passport_files)
      passport = passport_files.is_a?(Hash) ? passport_files['0'] : passport_files&.first
      admin.save_passport(passport) if admin.company.can_be_listed_as_public? && passport.present?
      render 'show'
    else
      render json: { errors: admin.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if current_admin == admin
      render json: { error: 'You cannot delete yourself' }, status: :bad_request and return
    end
    admin.destroy
    render json: [admin.id]
  end

  def destroy_many
    deleted_ids = params.require(:admin_ids).select do |admin_id|
      authorized_scope(company.admins).find_by(id: admin_id)&.destroy
    end

    render json: deleted_ids
  end

  private

  def admin
    @admin ||= if company
      authorized_scope(company.admins).find(params[:id])
    else
      # when creating a company we should be able to update our SSN
      current_admin
    end
  end

  def update_params
    record = admin rescue Admin
    params.require(:admin).permit(policy(record).permitted_attributes)
  end

  def create_params
    update_params.merge(without_password: true, locale: I18n.locale)
  end

  def company
    @company ||= current_admin.company
  end
end

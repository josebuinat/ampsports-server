class Admin::GroupCustomBillersController < Admin::BaseController
  def index
    @group_custom_billers = authorized_scope(company.group_custom_billers).
                                    includes(:groups).
                                    order(:created_at).
                                    paginate(page: params[:page])
  end

  def show
    group_custom_biller
  end

  def create
    @group_custom_biller = authorize GroupCustomBiller.new(group_custom_biller_params)

    if @group_custom_biller.save
      render 'show', status: :created
    else
      render json: { errors: group_custom_biller.errors }, status: :unprocessable_entity
    end
  end

  def update
    if group_custom_biller.update(group_custom_biller_params)
      render 'show'
    else
      render json: { errors: group_custom_biller.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if group_custom_biller.destroy
      render json: [group_custom_biller.id]
    else
      render nothing: true, status: :unprocessable_entity
    end
  end

  def destroy_many
    deleted = many_group_custom_billers.select do |group_custom_biller|
      group_custom_biller.destroy
    end

    render json: deleted.map(&:id)
  end

  # for custom biller form multi-select field of groups
  # returns groups without biller and with requested biller as options
  def groups_options
    render json: authorized_scope(company.groups).
                          includes(:owner).
                          where(custom_biller_id: [nil, params[:custom_biller_id]]).
                          order(:owner_id, :created_at).
                          map { |group| { value: group.id, label: "#{group.name}(#{group.owner.full_name})" } }
  end

  private

  def company
    current_admin.company
  end

  def group_custom_biller
    @group_custom_biller ||= authorized_scope(company.group_custom_billers).find(params[:id])
  end

  def many_group_custom_billers
    @many_group_custom_billers ||= authorized_scope(company.group_custom_billers).
                                           where(id: params[:group_custom_biller_ids])
  end

  def group_custom_biller_params
    params.require(:group_custom_biller).permit(
      :company_legal_name, :company_business_type, :company_tax_id,
      :bank_name, :company_iban, :company_bic, :country_id, :company_street_address,
      :company_zip, :company_city, :company_phone, :company_website, :invoice_sender_email,
      group_ids: []
    )
  end
end

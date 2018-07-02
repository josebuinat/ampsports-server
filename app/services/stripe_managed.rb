class StripeManaged < Struct.new(:company)

  def create_account!(admin, tos_accepted, ip)
    return nil unless tos_accepted
    country_code, currency = country_info(company.country.name)
    account_params = stripe_account_params(country_code, currency, ip, admin)
    @account = Stripe::Account.create(account_params)
    update_company_account(@account)
    @account
  end

  protected

  def account_status(account)
    {
      details_submitted: account.details_submitted,
      charges_enabled: account.charges_enabled,
      transfers_enabled: account.transfers_enabled,
      fields_needed: account.verification.fields_needed,
      due_by: account.verification.due_by
    }
  end

  def country_info(country)
    case country
    when 'Finland'
      %w(FI eur)
    when 'United States', 'USA'
      %w(US usd)
    end
  end

  def stripe_account_params(country_code, currency, ip, admin)
    account_params = base_stripe_account_params(country_code, currency, ip, admin)
    if country_code == 'US'
      account_params[:external_account][:routing_number] = company.usa_routing_number
      account_params[:legal_entity][:address][:state] = company.usa_state
      account_params[:legal_entity][:ssn_last_4] = company.admins.god.first.admin_ssn
    end
    account_params
  end

  def base_stripe_account_params(country_code, currency, ip, admin)
    {
      managed: true,
      country: country_code,
      business_name: company.company_legal_name,
      business_url: company.company_website,
      external_account: {
        object: 'bank_account',
        account_number: company.company_iban,
        country: country_code,
        currency: currency,
        account_holder_name: company.company_legal_name,
        account_holder_type: 'company',
      },
      legal_entity: {
        additional_owners: nil,
        dob: {
          day: admin.admin_birth_day,
          month: admin.admin_birth_month,
          year: admin.admin_birth_year
        },
        first_name: admin.first_name,
        last_name: admin.last_name,
        personal_address: {
          city: company.company_city,
          postal_code: company.company_zip,
          line1: company.company_street_address
        },
        address: {
          city: company.company_city,
          country: country_code,
          line1: company.company_street_address,
          postal_code: company.company_zip
        },
        business_name: company.company_legal_name,
        business_vat_id: company.company_tax_id,
        business_tax_id: company.company_tax_id,
        phone_number: company.company_phone,
        type: 'company'
      },
      tos_acceptance: {
        ip: ip,
        date: Time.current.to_i
      }
    }
  end

  def update_company_account(stripe_account)
    company.update_attributes(
      currency: stripe_account.default_currency,
      stripe_account_type: 'managed',
      stripe_user_id: stripe_account.id,
      secret_key: stripe_account.keys.secret,
      publishable_key: stripe_account.keys.publishable,
      stripe_account_status: account_status(stripe_account)
    )
  end
end

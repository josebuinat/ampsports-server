class ReportPolicy < Struct.new(:user, :reports)
  def index?
    show?
  end

  def payment_transfers?
    show?
  end

  def show?
    user.can?(:reports, :read)
  end

  def download_sales_report?
    user.can?(:reports, :read)
  end

  def download_invoices_report?
    user.can?(:reports, :read)
  end

  def sport_name_options?
    user.can?(:reports, :read) || user.can?(:venues, :read) || user.can?(:dashboard, :read)
  end
end

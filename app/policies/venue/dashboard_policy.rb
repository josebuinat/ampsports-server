class Venue::DashboardPolicy < Struct.new(:user, :venue_dashboard)
  def show?
    user.can?(:dashboard, :read) || user.can?(:venues, :read) || user.can?(:reports, :read)
  end
end

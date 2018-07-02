class MembershipMailer < ApplicationMailer
  add_template_helper ApplicationHelper
  add_template_helper LayoutsHelper

  def self.subject_for_membership(membership, method_name)
    I18n.t("membership_mailer.#{method_name}.subject",
      venue_name: membership.venue.venue_name,
      date: I18n.l(TimeSanitizer.output(membership.start_time), format: :easy))
  end

  def self.comment_for_membership(method_name)
    I18n.t("membership_mailer.#{method_name}.description")
  end


  membership_actions = %i(membership_created membership_updated membership_created_for_coach)

  membership_actions.each do |method_name|
    define_method method_name do |user, membership|
      return if disabled_reservation_email_by_user(user, method_name)
      return if disabled_company_level_email(membership.company, method_name)
      @membership = membership
      prepare_instance_variables(@membership, user) do
        @comment = self.class.comment_for_membership(method_name)
        mail(to: @user.email,
          template_name: 'membership_mail',
          subject: self.class.subject_for_membership(membership, method_name.to_s))
      end
    end
  end

  private

  def prepare_instance_variables(membership, user, &block)
    @user = user
    @first_reservation = membership.reservations.first
    # have to assign @venue, because _footer_address partial needs it
    @venue = @first_reservation.venue
    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        yield if block_given?
      end
    end
  end
end

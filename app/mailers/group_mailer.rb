class GroupMailer < ApplicationMailer

  # def added_to_the_group(group, user)
  #
  # end
  #
  # def removed_from_the_group(group, user)
  #   @user = user
  #   @group = group
  #   @venue = @group.venue
  #
  #   return if disabled_company_level_email(@venue.company, :removed_from_the_group)
  #
  #   I18n.with_locale(user.locale) do
  #     Time.with_user_clock_type(user) do
  #       mail(
  #         to: user.email,
  #         subject: t('group_mailer.removed_from_the_group.subject', venue_name: @venue.venue_name),
  #       )
  #     end
  #   end
  # end

  # Call methods like this: GroupMailer.added_to_the_group(group, user)
  %i(
    added_to_the_group
    removed_from_the_group
    coach_added_to_the_group
    coach_removed_from_the_group
  ).each do |method_name|

    define_method method_name do |group, recipient|
      send_the_mail(group, recipient, method_name)
    end
  end


  private

  def send_the_mail(group, recipient, method_name)
    @method_name = method_name
    @group = group
    venue = @group.venue

    return if disabled_company_level_email(venue.company, method_name)

    I18n.with_locale(recipient.locale) do
      Time.with_user_clock_type(recipient) do
        mail(
          to: recipient.email,
          subject: t("group_mailer.#{method_name}.subject", venue_name: venue.venue_name),
          template_name: 'group_mail',
        )
      end
    end
  end
end

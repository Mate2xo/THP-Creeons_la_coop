# frozen_string_literal: true

class MemberMailer < ApplicationMailer
  def end_subscription_alert(member)
    @member = member
    mail(to: @member.email, subject: t("mailer.member.alert.subject"))
  end
end

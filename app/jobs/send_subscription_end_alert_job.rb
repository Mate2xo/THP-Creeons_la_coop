# frozen_string_literal: true

class SendSubscriptionEndAlertJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    end_subscription_period = { start_date: Date.today, end_date: Date.today + 15 }
    members = Member.where(":start_date <= end_subscription AND end_subscription <= :end_date", end_subscription_period).find_each(batch_size: 200) do |member|
      MemberMailer.end_subscription_alert(member).deliver_now
    end
  end
end

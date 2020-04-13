# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendSubscriptionEndAlertJob, type: :job do
  subject { ActionMailer::Base.deliveries }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  context "when some members' subscription are ending soon" do
    it "sends an end of subscription alert mail to them" do
      end_subscription_period_params = { from: Date.today, to: Date.today + 15 }
      create_list :member, 5, end_subscription: Faker::Date.between(end_subscription_period_params)
      member_mails = Member.all.map(&:email)
      SendSubscriptionEndAlertJob.perform_now

      expect(subject.map { |m| m.to[0] }).to match_array(member_mails)
    end
  end

  context "when members' subscription are NOT ending soon" do
    it "does not send them an end of subscription alert mail" do
      before_end_subscription_period_params = { from: Date.today + 16, to: Date.today + 300 }
      create_list :member, 5, end_subscription: Faker::Date.between(before_end_subscription_period_params)
      SendSubscriptionEndAlertJob.perform_now

      expect(subject.size).to eq(0)
    end
  end

  context "when members' end_subscription are outdated" do
    it "does not send them an end of subscription alert mail" do
      after_end_subscription_period_params = { from: Date.today - 1, to: Date.today - 300 }
      create_list :member, 5, end_subscription: Faker::Date.between(after_end_subscription_period_params)
      SendSubscriptionEndAlertJob.perform_now

      expect(subject.size).to eq(0)
    end
  end

  context "when members have a nil end_subscription date" do
    it "does not send them an end of subscription alert mail" do
      create_list :member, 5, end_subscription: nil
      SendSubscriptionEndAlertJob.perform_now

      expect(subject.size).to eq(0)
    end
  end
end

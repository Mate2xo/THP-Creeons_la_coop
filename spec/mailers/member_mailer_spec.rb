# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemberMailer, type: :mailer do
  describe "#end_subscription_alert" do
    context "when a mail is sended" do
      let (:member) { create :member }
      let (:mail) { MemberMailer.end_subscription_alert(member) }

      it "contain the first name of member" do
        expect(mail.body.encoded).to match(/#{member.first_name}/)
      end

      it "contain the last name of member" do
        expect(mail.body.encoded).to match(/#{member.last_name}/)
      end

      it "contain the end subscription date of the member" do
        expect(mail.body.encoded).to match(/#{member.end_subscription}/)
      end
    end
  end
end

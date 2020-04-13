# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:noreply_mail_address) || 'no-reply@example.com'
  layout 'mailer'
end

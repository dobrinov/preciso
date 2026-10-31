class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "Preciso <orders@precisodesign.com>") }
  layout "mailer"
  helper ApplicationHelper
end

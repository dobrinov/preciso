class NotificationSetting < ApplicationRecord
  # Singleton: the studio's own address for order notifications (also the
  # reply-to on customer emails).
  def self.instance
    first || create!
  end

  validates :studio_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end

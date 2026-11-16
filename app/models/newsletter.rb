# One announcement the studio sent to every active subscriber (new pieces,
# an offer, a studio event). NewsletterJob delivers it and keeps the counts.
class Newsletter < ApplicationRecord
  STATUSES = { "sending" => "Sending", "sent" => "Sent", "failed" => "Failed" }.freeze

  validates :subject, presence: true, length: { maximum: 200 }
  validates :body, presence: true
  validate :button_link_valid

  scope :recent_first, -> { order(created_at: :desc) }

  def status_label = STATUSES[status] || status

  private

  def button_link_valid
    return if button_url.blank?
    uri = URI.parse(button_url) rescue nil
    errors.add(:button_url, "must be a full web address starting with https://") unless uri.is_a?(URI::HTTP) && uri.host.present?
    errors.add(:button_label, "is needed for the button link") if button_label.blank?
  end
end

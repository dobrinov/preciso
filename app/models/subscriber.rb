# Someone who asked to hear about new pieces, offers and studio events —
# from the footer form or the checkout tick-box. Email is stored lowercased
# and unique; unsubscribing keeps the row (with unsubscribed_at) so a later
# re-subscribe is an explicit choice, not an accident.
class Subscriber < ApplicationRecord
  SOURCES = { "footer" => "Website", "checkout" => "Checkout", "admin" => "Added by you" }.freeze

  has_secure_token :token
  normalizes :email, with: ->(e) { e.to_s.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }

  scope :active, -> { where(unsubscribed_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Subscribe (or re-subscribe) an address. Returns the subscriber, or nil if
  # the email is invalid. An existing active subscriber is left untouched.
  def self.subscribe(email, name: nil, source: "footer", sid: nil)
    sub = find_or_initialize_by(email: email.to_s.strip.downcase)
    sub.name = name.to_s.strip.first(100).presence || sub.name
    sub.source = source if sub.new_record?
    sub.sid ||= sid
    sub.unsubscribed_at = nil
    sub.save ? sub : nil
  end

  def active? = unsubscribed_at.nil?
  def source_label = SOURCES[source] || source

  def unsubscribe!
    update!(unsubscribed_at: Time.current) if active?
  end
end

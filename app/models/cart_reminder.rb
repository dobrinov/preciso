# A shopper who typed their email at checkout, ticked "remind me", and left
# without finishing. CartReminderSweep emails them `delay_hours` later with a
# link that restores their cart (and, optionally, a discount) — unless they
# ordered in the meantime.
class CartReminder < ApplicationRecord
  STATUSES = {
    "pending" => "Waiting", "sent" => "Sent", "converted" => "Ordered",
    "cancelled" => "Not sent", "failed" => "Failed", "unsubscribed" => "Unsubscribed"
  }.freeze

  belongs_to :order, optional: true
  serialize :items, type: Array, coder: JSON
  serialize :eligible_keys, type: Array, coder: JSON

  has_secure_token :token
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :due, -> { where(status: "pending").where("send_at <= ?", Time.current) }
  scope :recent_first, -> { order(created_at: :desc) }

  def self.unsubscribed?(email) = where(status: "unsubscribed").where("lower(email) = ?", email.to_s.downcase).exists?

  # Discount usable right now via the email link?
  def offer_active?
    status == "sent" && discount_percent.to_i.positive? && expires_at&.future?
  end

  def eligible?(kind, id) = Array(eligible_keys).include?("#{kind}/#{id}")

  def status_label = STATUSES[status] || status

  # Snapshot lines resolved to live records (deleted items drop out).
  def lines
    Array(items).filter_map do |i|
      rec = i["kind"] == "set" ? ProductSet.find_by(id: i["id"]) : Product.find_by(id: i["id"])
      next unless rec
      variant = Variant.find_by(id: i["variant_id"]) if i["variant_id"].present?
      Cart::Line.new(kind: i["kind"], id: i["id"], qty: i["qty"].to_i, record: rec, variant: variant)
    end
  end

  # An order from this address placed (and not left unpaid) after the reminder
  # was created means the shopper came back on their own.
  def ordered_since?
    Order.where("lower(customer_email) = ?", email.downcase).where("created_at >= ?", created_at)
         .where.not(status: "cancelled").where(payment_status: %w[none paid]).exists?
  end
end

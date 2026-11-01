class Order < ApplicationRecord
  has_many :order_lines, dependent: :destroy
  has_many :email_logs, dependent: :destroy

  STATUSES = {
    "new"       => { label: "New",       color: "#9c8264", bg: "#f3ede4" },
    "preparing" => { label: "Preparing", color: "#4a5a6a", bg: "#e9eef1" },
    "fulfilled" => { label: "Fulfilled", color: "#5a7060", bg: "#e8efe9" },
    "cancelled" => { label: "Cancelled", color: "#9a9088", bg: "#efece8" }
  }.freeze
  STATUS_ORDER = %w[new preparing fulfilled cancelled].freeze

  # Online payment (myPOS). "none" = no online payment was attempted (myPOS off,
  # or orders from before it). Only "pending"/"failed" orders are hidden from the
  # studio's normal order lists — they are checkouts that never got paid.
  PAYMENT_STATUSES = {
    "none"    => "Not paid online",
    "pending" => "Awaiting payment",
    "paid"    => "Paid",
    "failed"  => "Payment failed"
  }.freeze

  validates :status, inclusion: { in: STATUSES.keys }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES.keys }

  default_scope { order(created_at: :desc) }
  scope :active, -> { where.not(status: "cancelled") }
  scope :placed, -> { where(payment_status: %w[none paid]) }
  scope :unpaid, -> { where(payment_status: %w[pending failed]) }

  def status_meta = STATUSES[status] || STATUSES["new"]
  def item_count = order_lines.sum(:qty)
  def payment_label = PAYMENT_STATUSES[payment_status]
  def items_total = order_lines.sum(&:subtotal)
  # A fixed delivery price applied (a DeliveryOption was chosen). nil = the
  # studio quotes delivery by hand.
  def delivery_priced? = !delivery_cost.nil?

  # "Bulgaria · Econt office" — for summaries and the myPOS cart row.
  def delivery_label
    [ country_name, delivery_option_name ].compact_blank.join(" · ")
  end

  def office_delivery? = delivery_kind == "office"

  # Where it goes, line by line (without the customer's name).
  def delivery_lines
    if office_delivery?
      [ "#{delivery_option_name.presence || "Courier office"}: #{delivery_office}", city, country_name ]
    else
      [ address_line, [ postal_code, city ].compact_blank.join(" "), country_name ]
    end.compact_blank
  end

  def delivery_destination? = address_line.present? || delivery_office.present?

  # Delivery in a few words, for customer-facing copy:
  # "to the Speedy office you chose" / "to your address" / "to you".
  def delivery_phrase
    if office_delivery? then "to the #{delivery_option_name.presence || "courier office"} you chose"
    elsif address_line.present? then "to your address"
    else "to you"
    end
  end

  # Delivery to a country without a set price — the studio quotes it.
  def delivery_to_quote? = country_name.present? && !delivery_priced?
  def paid? = payment_status == "paid"
  def awaiting_payment? = payment_status == "pending"

  def self.next_number
    base = 1043
    "PR-#{base + Order.unscoped.where("number LIKE ?", "PR-%").count}"
  end

  def to_param = number
end

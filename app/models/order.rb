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
  # or orders from before it). "requested" = the studio confirmed delivery and
  # emailed a payment link (still a real order). Only "pending"/"failed" orders are hidden from the
  # studio's normal order lists — they are checkouts that never got paid.
  PAYMENT_STATUSES = {
    "none"      => "Not paid online",
    "requested" => "Payment link sent",
    "pending"   => "Awaiting payment",
    "paid"    => "Paid",
    "failed"  => "Payment failed"
  }.freeze

  validates :status, inclusion: { in: STATUSES.keys }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES.keys }

  default_scope { order(created_at: :desc) }
  scope :active, -> { where.not(status: "cancelled") }
  scope :placed, -> { where(payment_status: %w[none requested paid]) }
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
  # The studio will check delivery and email a card payment link.
  def awaiting_quote? = delivery_to_quote? && payment_status == "none" && Mypos.enabled?
  def paid? = payment_status == "paid"

  def any_made_to_order? = order_lines.any? { |l| !l.from_stock }
  def all_from_stock? = !any_made_to_order?

  # Take the ready-to-ship lines off the studio's stock, once — when the order
  # is placed (pay-later) or paid (card).
  def take_stock!
    return if stock_taken_at
    order_lines.select(&:from_stock).each { |l| l.stock_holder&.take_stock!(l.qty) }
    update!(stock_taken_at: Time.current)
  end

  # Cancelled: put those pieces back on the shelf.
  def return_stock!
    return unless stock_taken_at
    order_lines.select(&:from_stock).each { |l| l.stock_holder&.return_stock!(l.qty) }
    update!(stock_taken_at: nil)
  end
  def awaiting_payment? = payment_status == "pending"
  def payment_link_sent? = payment_status == "requested"
  # Can be paid by card right now: a checkout heading to myPOS, or an order the
  # studio confirmed and sent a payment link for.
  def payable_online? = (awaiting_payment? || payment_link_sent?) && status != "cancelled"
  # The studio can confirm delivery and send (or re-send) a payment link.
  def payment_link_possible? = payment_status.in?(%w[none requested]) && status != "cancelled"

  # Studio confirmed it can deliver: fix the delivery cost and total, ready for
  # the customer to pay through the emailed link.
  def confirm_for_payment!(delivery_cost:, note:)
    update!(delivery_cost: delivery_cost, quote_note: note.presence,
            total: items_total + delivery_cost, payment_status: "requested",
            payment_link_sent_at: Time.current)
  end

  def self.next_number
    base = 1043
    "PR-#{base + Order.unscoped.where("number LIKE ?", "PR-%").count}"
  end

  def to_param = number
end

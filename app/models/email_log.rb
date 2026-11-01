# One row per order email the shop tried to send, so the studio can see in
# admin what went out, when, to whom — and why not, when it didn't.
# "sent" means the mail server (Brevo) accepted it; inbox placement (spam,
# opens, bounces) is only visible in Brevo's own logs.
class EmailLog < ApplicationRecord
  belongs_to :order, optional: true

  STATUSES = %w[queued sent failed skipped].freeze
  KINDS = {
    "received" => "Order received",
    "paid" => "Payment received",
    "status_changed" => "Status update",
    "studio_new_order" => "New order (to you)"
  }.freeze

  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: KINDS.keys }

  default_scope { order(:created_at) }

  def label = KINDS[kind]
  def to_customer? = kind != "studio_new_order"
end

class Order < ApplicationRecord
  has_many :order_lines, dependent: :destroy

  STATUSES = {
    "new"       => { label: "New",       color: "#9c8264", bg: "#f3ede4" },
    "preparing" => { label: "Preparing", color: "#4a5a6a", bg: "#e9eef1" },
    "fulfilled" => { label: "Fulfilled", color: "#5a7060", bg: "#e8efe9" },
    "cancelled" => { label: "Cancelled", color: "#9a9088", bg: "#efece8" },
  }.freeze
  STATUS_ORDER = %w[new preparing fulfilled cancelled].freeze

  validates :status, inclusion: { in: STATUSES.keys }

  default_scope { order(created_at: :desc) }
  scope :active, -> { where.not(status: "cancelled") }

  def status_meta = STATUSES[status] || STATUSES["new"]
  def item_count = order_lines.sum(:qty)

  def self.next_number
    base = 1043
    "PR-#{base + Order.unscoped.where("number LIKE ?", "PR-%").count}"
  end

  def to_param = number
end

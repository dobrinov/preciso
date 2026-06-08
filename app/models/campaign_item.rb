class CampaignItem < ApplicationRecord
  belongs_to :campaign

  KINDS = %w[product set].freeze
  DISCOUNT_KINDS = %w[fixed percent].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :discount_kind, inclusion: { in: DISCOUNT_KINDS }
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :percent_off, numericality: { in: 1..99 }, allow_nil: true
  # Guard against a discount that resolves to a free/zero price: each kind
  # requires its own value (price_for would otherwise coerce a nil to 0).
  validates :sale_price, presence: true, if: -> { discount_kind == "fixed" }
  validates :percent_off, presence: true, if: -> { discount_kind == "percent" }

  # The discounted price for a given base (integer €).
  def price_for(base)
    case discount_kind
    when "percent" then (base * (100 - percent_off.to_i) / 100.0).round
    else [ sale_price.to_i, base ].min
    end
  end

  # Resolve the catalogue record this item points at.
  def record
    kind == "set" ? ProductSet.find_by(id: item_id) : Product.find_by(id: item_id)
  end
end

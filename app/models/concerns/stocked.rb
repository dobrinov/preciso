# Something the studio may hold ready-made stock of (Product without
# variations, Variant, ProductSet). `stock` nil/0 means made to order.
# The count is admin-only — the storefront only ever says "ready to ship" or
# "made to order".
module Stocked
  extend ActiveSupport::Concern

  included do
    validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  end

  def in_stock?(qty = 1) = stock.to_i >= qty.to_i && qty.to_i.positive?

  def take_stock!(qty)
    with_lock { update!(stock: [ stock.to_i - qty, 0 ].max) }
  end

  def return_stock!(qty)
    with_lock { update!(stock: stock.to_i + qty) }
  end
end

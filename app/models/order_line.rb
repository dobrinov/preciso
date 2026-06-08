class OrderLine < ApplicationRecord
  belongs_to :order

  # Resolve the live catalogue record (product or set) for thumbnail display.
  def record
    @record ||= kind == "set" ? ProductSet.find_by(id: item_id) : Product.find_by(id: item_id)
  end

  def subtotal = price * qty
end

class OrderLine < ApplicationRecord
  belongs_to :order

  # Resolve the live catalogue record (product or set) for thumbnail display.
  def record
    @record ||= kind == "set" ? ProductSet.find_by(id: item_id) : Product.find_by(id: item_id)
  end

  def subtotal = price * qty

  # The live Product/Variant/ProductSet whose stock this line draws on.
  def stock_holder
    return record if kind == "set"
    variant_id ? Variant.find_by(id: variant_id) : record
  end

  def display_name
    variant_label.present? ? "#{name} — #{variant_label}" : name
  end
end

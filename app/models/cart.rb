# Session-backed cart. Lines are plain hashes: {"kind"=>, "id"=>, "variant_id"=>, "qty"=>}.
# variant_id is nil for sets and variant-less products.
class Cart
  # A resolved line: record is the live Product/ProductSet, variant the live
  # Variant (or nil). current_price ignores a nil variant.
  Line = Struct.new(:kind, :id, :qty, :record, :variant, keyword_init: true) do
    def unit_price = record.current_price(variant: variant)
    def subtotal = unit_price * qty
  end

  def initialize(session)
    @session = session
    @session[:cart] ||= []
  end

  def raw = @session[:cart]

  def add(kind, id, variant_id = nil)
    id = id.to_s
    variant_id = variant_id.presence&.to_s
    line = find(kind, id, variant_id)
    if line
      line["qty"] += 1
    else
      raw << { "kind" => kind, "id" => id, "variant_id" => variant_id, "qty" => 1 }
    end
  end

  def set_qty(kind, id, qty, variant_id = nil)
    line = find(kind, id.to_s, variant_id.presence&.to_s)
    line["qty"] = qty.to_i if line
    raw.reject! { |l| l["qty"].to_i <= 0 }
  end

  def remove(kind, id, variant_id = nil)
    variant_id = variant_id.presence&.to_s
    raw.reject! { |l| l["kind"] == kind && l["id"] == id.to_s && l["variant_id"] == variant_id }
  end

  def clear = raw.clear

  def detailed
    raw.filter_map do |l|
      rec = l["kind"] == "set" ? ProductSet.find_by(id: l["id"]) : Product.find_by(id: l["id"])
      next unless rec

      # A line that names a variant which no longer exists is dropped, the same
      # way a deleted product/set drops out — rather than silently falling back
      # to the product's base price (which would be a wrong charge).
      if l["variant_id"].present?
        variant = Variant.find_by(id: l["variant_id"])
        next unless variant
      else
        variant = nil
      end
      Line.new(kind: l["kind"], id: l["id"], qty: l["qty"].to_i, record: rec, variant: variant)
    end
  end

  def count = raw.sum { |l| l["qty"].to_i }
  def total = detailed.sum(&:subtotal)
  def empty? = raw.empty?

  private

  def find(kind, id, variant_id = nil) = raw.find { |l| l["kind"] == kind && l["id"] == id && l["variant_id"] == variant_id }
end

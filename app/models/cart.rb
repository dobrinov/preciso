# Session-backed cart. Lines are plain hashes: {"kind"=>, "id"=>, "qty"=>}.
class Cart
  # :variant is nil until product variations land (Phase 4 populates it from
  # the session line and resolves it in #detailed); current_price ignores nil.
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

      variant = l["variant_id"].present? ? Variant.find_by(id: l["variant_id"]) : nil
      Line.new(kind: l["kind"], id: l["id"], qty: l["qty"].to_i, record: rec, variant: variant)
    end
  end

  def count = raw.sum { |l| l["qty"].to_i }
  def total = detailed.sum(&:subtotal)
  def empty? = raw.empty?

  private

  def find(kind, id, variant_id = nil) = raw.find { |l| l["kind"] == kind && l["id"] == id && l["variant_id"] == variant_id }
end

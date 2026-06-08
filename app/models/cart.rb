# Session-backed cart. Lines are plain hashes: {"kind"=>, "id"=>, "qty"=>}.
class Cart
  Line = Struct.new(:kind, :id, :qty, :record, :variant, keyword_init: true) do
    def unit_price = record.current_price(variant: variant)
    def subtotal = unit_price * qty
  end

  def initialize(session)
    @session = session
    @session[:cart] ||= []
  end

  def raw = @session[:cart]

  def add(kind, id)
    id = id.to_s
    line = find(kind, id)
    if line
      line["qty"] += 1
    else
      raw << { "kind" => kind, "id" => id, "qty" => 1 }
    end
  end

  def set_qty(kind, id, qty)
    line = find(kind, id.to_s)
    line["qty"] = qty.to_i if line
    raw.reject! { |l| l["qty"].to_i <= 0 }
  end

  def remove(kind, id)
    raw.reject! { |l| l["kind"] == kind && l["id"] == id.to_s }
  end

  def clear = raw.clear

  def detailed
    raw.filter_map do |l|
      rec = l["kind"] == "set" ? ProductSet.find_by(id: l["id"]) : Product.find_by(id: l["id"])
      Line.new(kind: l["kind"], id: l["id"], qty: l["qty"].to_i, record: rec) if rec
    end
  end

  def count = raw.sum { |l| l["qty"].to_i }
  def total = detailed.sum(&:subtotal)
  def empty? = raw.empty?

  private

  def find(kind, id) = raw.find { |l| l["kind"] == kind && l["id"] == id }
end

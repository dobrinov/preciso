class CartController < ApplicationController
  def add
    current_cart.add(params[:kind], params[:id], params[:variant_id])
    @toast = "#{params[:name].presence || 'Item'} added"
    track_cart("add_cart", 1)
    respond
  end

  def update
    before = line_qty
    current_cart.set_qty(params[:kind], params[:id], params[:qty], params[:variant_id])
    diff = line_qty - before
    track_cart(diff.positive? ? "add_cart" : "remove_cart", diff.abs) unless diff.zero?
    respond
  end

  def remove
    track_cart("remove_cart", line_qty)
    current_cart.remove(params[:kind], params[:id], params[:variant_id])
    respond
  end

  private

  def line_qty
    current_cart.raw.find { |l| l["kind"] == params[:kind] && l["id"] == params[:id].to_s && l["variant_id"] == params[:variant_id].presence&.to_s }&.dig("qty").to_i
  end

  def track_cart(type, qty)
    kind = params[:kind] == "set" ? "set" : "product"
    record = (kind == "set" ? ProductSet : Product).find_by(id: params[:id])
    record_event(type, page_key: "#{kind}/#{params[:id]}", label: record&.name || params[:name],
                       name: record&.name, piece: true, qty: qty)
  end

  def respond
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end
end

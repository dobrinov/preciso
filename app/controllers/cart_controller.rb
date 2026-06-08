class CartController < ApplicationController
  def add
    current_cart.add(params[:kind], params[:id], params[:variant_id])
    @toast = "#{params[:name].presence || 'Item'} added"
    respond
  end

  def update
    current_cart.set_qty(params[:kind], params[:id], params[:qty], params[:variant_id])
    respond
  end

  def remove
    current_cart.remove(params[:kind], params[:id], params[:variant_id])
    respond
  end

  private

  def respond
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end
end

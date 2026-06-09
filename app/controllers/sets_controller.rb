class SetsController < ApplicationController
  def index
    @sets = ProductSet.order(:id)
    track("sets", "Sets")
  end

  def show
    @set = ProductSet.find_by(id: params[:id])
    return render "shared/not_found", status: :not_found unless @set

    @grouped = @set.grouped_items
    @meta_title = @set.name
    @meta_image = @set.image
    @meta_type = "product"
    @meta_price = @set.current_price
    @meta_description = [ "€#{@set.current_price}", @set.short.presence || @set.long_desc ].compact.join(" — ").squish.truncate(200)
    track("set/#{@set.id}", @set.name, piece: true, name: "#{@set.name} (set)")
  end
end

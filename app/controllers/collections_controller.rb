class CollectionsController < ApplicationController
  def index
    @collections = Collection.nonempty.includes(:products, cover_attachment: :blob)
    track("collections", "Collections")
  end

  def show
    @collection = Collection.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @collection

    # @collection.products inherits the membership order(:position) scope (curated order)
    @products = @collection.products
    track("collection/#{@collection.slug}", "Collection · #{@collection.name}")
  end
end

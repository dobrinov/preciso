class CollectionsController < ApplicationController
  def index
    @collections = Collection.nonempty.includes(:products)
    track("collections", "Collections")
  end

  def show
    @collection = Collection.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @collection

    @products = @collection.products.order(:id)
    track("collection/#{@collection.slug}", "Collection · #{@collection.name}")
  end
end

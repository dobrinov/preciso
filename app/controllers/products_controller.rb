class ProductsController < ApplicationController
  def show
    @product = Product.find_by(id: params[:id])
    return render "shared/not_found", status: :not_found unless @product

    @category = @product.category
    @related = @category ? @category.products.where.not(id: @product.id).order(:id).limit(4) : []
    track("product/#{@product.id}", @product.name, piece: true, name: @product.name)
  end
end

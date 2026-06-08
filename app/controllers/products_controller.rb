class ProductsController < ApplicationController
  def show
    @product = Product.with_attached_images.find_by(id: params[:id])
    return render "shared/not_found", status: :not_found unless @product

    @variants = @product.variants.includes(:variant_attribute_values, images_attachments: :blob)
    @category = @product.category
    @related = @category ? @category.products.where.not(id: @product.id).order(:id).limit(4) : []
    track("product/#{@product.id}", @product.name, piece: true, name: @product.name)
  end
end

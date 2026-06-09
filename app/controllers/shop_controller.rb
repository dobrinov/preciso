class ShopController < ApplicationController
  def show
    @category = Category.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @category

    @products = @category.products.order(:id)
    @meta_title = @category.name
    @meta_image = @category.image
    @meta_description = @category.blurb.presence || "Handmade porcelain #{@category.name.downcase} by Preciso."
    track("shop/#{@category.slug}", "Shop · #{@category.name}")
  end
end

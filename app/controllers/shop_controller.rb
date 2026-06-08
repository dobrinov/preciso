class ShopController < ApplicationController
  def show
    @category = Category.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @category

    @products = @category.products.order(:id)
    track("shop/#{@category.slug}", "Shop · #{@category.name}")
  end
end

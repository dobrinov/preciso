class SitemapsController < ApplicationController
  def show
    @categories = Category.all
    @products = Product.order(:id)
    @sets = ProductSet.order(:id)
    @collections = Collection.all
    @campaigns = Campaign.active
  end
end

class HomeController < ApplicationController
  def index
    @categories = Category.all
    @featured = Product.order(:id).limit(4)
    @hero_set = ProductSet.order(:id).first
    track("home", "Home")
  end
end

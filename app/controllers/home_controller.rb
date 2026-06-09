class HomeController < ApplicationController
  def index
    @categories = Category.all
    @featured = Product.order(:id).limit(4)
    # Featured hero slot: active campaign wins, else the admin pick, else nothing.
    @featured_item = Campaign.active.first || HomePage.instance.featured_record
    @about = About.instance
    track("home", "Home")
  end
end

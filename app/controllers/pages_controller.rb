class PagesController < ApplicationController
  def about
    @about = About.instance
    track("about", "About")
  end
end

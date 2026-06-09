class PagesController < ApplicationController
  def about
    @about = About.instance
    @meta_title = @about.title
    @meta_image = @about.image
    @meta_description = @about.lead
    track("about", "About")
  end
end

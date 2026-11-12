class PagesController < ApplicationController
  def about
    @about = About.instance
    @meta_title = @about.title
    @meta_image = @about.image
    @meta_description = @about.lead
    track("about", "About")
  end

  def legal
    @key = params[:page]
    @page = LegalInfo.page(@key)
    @legal = LegalInfo.instance
    @meta_title = @page[:title]
    track("legal_#{@key}", @page[:title])
  end
end

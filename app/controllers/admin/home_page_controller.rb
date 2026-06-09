module Admin
  class HomePageController < BaseController
    def edit
      @home = HomePage.instance
    end

    def update
      @home = HomePage.instance
      kind, id = params[:featured].to_s.split(":", 2)
      kind = nil unless HomePage::FEATURED_KINDS.include?(kind)
      @home.update(
        hero_eyebrow: params[:hero_eyebrow],
        hero_title: params[:hero_title].to_s,
        hero_accent: params[:hero_accent],
        hero_subtext: params[:hero_subtext],
        maker_eyebrow: params[:maker_eyebrow],
        maker_title: params[:maker_title],
        maker_text: params[:maker_text],
        footer_blurb: params[:footer_blurb],
        featured_kind: kind,
        featured_id: (kind ? id : nil)
      )
      redirect_to edit_admin_home_page_path, notice: "Saved"
    end
  end
end

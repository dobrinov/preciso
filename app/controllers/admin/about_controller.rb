module Admin
  class AboutController < BaseController
    def edit
      @about = About.instance
    end

    def update
      @about = About.instance
      @about.update(
        title: params[:title],
        lead: params[:lead],
        body: Array(params[:body]).map(&:to_s).reject { |p| p.strip.empty? },
        signature: params[:signature],
        studio: params[:studio]
      )
      @about.image.attach(params[:image]) if params[:image].present?
      @about.image.purge if params[:remove_image] == "1"
      redirect_to edit_admin_about_path, notice: "Saved"
    end
  end
end

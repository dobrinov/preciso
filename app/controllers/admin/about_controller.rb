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
      redirect_to edit_admin_about_path, notice: "Saved"
    end
  end
end

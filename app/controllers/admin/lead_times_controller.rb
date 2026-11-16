module Admin
  class LeadTimesController < BaseController
    def edit
      @lead_time = LeadTime.instance
    end

    def update
      LeadTime.instance.update(ready_note: params[:ready_note].to_s.strip, made_note: params[:made_note].to_s.strip)
      redirect_to edit_admin_lead_times_path, notice: "Saved"
    end
  end
end

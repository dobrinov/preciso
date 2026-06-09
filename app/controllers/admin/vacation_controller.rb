module Admin
  class VacationController < BaseController
    def edit
      @vacation = Vacation.instance
    end

    def update
      @vacation = Vacation.instance
      @vacation.update(active: params[:active] == "1", message: params[:message])
      redirect_to edit_admin_vacation_path, notice: "Saved"
    end
  end
end

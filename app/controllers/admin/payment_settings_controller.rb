module Admin
  class PaymentSettingsController < BaseController
    def edit
      @setting = PaymentSetting.instance
    end

    def update
      @setting = PaymentSetting.instance
      @setting.update(card_payments: params[:card_payments] == "1")
      redirect_to edit_admin_payments_path, notice: "Saved"
    end
  end
end

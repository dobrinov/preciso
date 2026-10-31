module Admin
  class NotificationSettingsController < BaseController
    def edit
      @setting = NotificationSetting.instance
    end

    def update
      @setting = NotificationSetting.instance
      if @setting.update(studio_email: params[:studio_email].to_s.strip)
        redirect_to edit_admin_emails_path, notice: "Saved"
      else
        redirect_to edit_admin_emails_path, alert: "That doesn't look like an email address."
      end
    end

    # Sends a test email to the studio address, synchronously, so any error
    # shows up right here.
    def test
      to = NotificationSetting.instance.studio_email
      return redirect_to(edit_admin_emails_path, alert: "Save your email address first.") if to.blank?
      return redirect_to(edit_admin_emails_path, alert: "Email sending isn't set up on the server yet.") unless Notifier.configured?
      OrderMailer.test_message(to).deliver_now
      redirect_to edit_admin_emails_path, notice: "Test email sent to #{to}"
    rescue => e
      redirect_to edit_admin_emails_path, alert: "Sending failed: #{e.message}"
    end
  end
end

module Admin
  # Admin → Cart reminders: switch the abandoned-cart email on/off, configure
  # its timing and offer, and see who was reminded and who came back.
  class CartRemindersController < BaseController
    def index
      @setting = CartReminderSetting.instance
      @products = Product.order(:name)
      @sets = ProductSet.order(:name)
      @filter = params[:status].presence_in(CartReminder::STATUSES.keys)
      scope = CartReminder.recent_first.includes(:order)
      @reminders = (@filter ? scope.where(status: @filter) : scope).limit(100)
      @counts = CartReminder.group(:status).count
      recent = CartReminder.where("created_at >= ?", 30.days.ago)
      sent = recent.where.not(sent_at: nil)
      @stats = {
        captured: recent.count,
        sent: sent.count,
        opened: sent.where.not(opened_at: nil).count,
        ordered: sent.where(status: "converted").count,
        revenue: Order.where(id: sent.where(status: "converted").where.not(used_order_id: nil).select(:used_order_id)).sum(:total)
      }
    end

    def update
      @setting = CartReminderSetting.instance
      p = params.require(:setting)
      keys = Array(p[:item_keys]).compact_blank
      if @setting.update(enabled: p[:enabled] == "1", delay_hours: p[:delay_hours], discount_percent: p[:discount_percent],
                         valid_days: p[:valid_days], min_cart_total: p[:min_cart_total].presence || 0,
                         applies_to: p[:applies_to], item_keys: keys,
                         subject: p[:subject].to_s.strip, message: p[:message].to_s.strip)
        redirect_to admin_cart_reminders_path, notice: "Saved"
      else
        redirect_to admin_cart_reminders_path, alert: @setting.errors.full_messages.to_sentence
      end
    end

    def send_due
      return redirect_to(admin_cart_reminders_path, alert: "Switch reminders on first.") unless CartReminderSetting.enabled?
      sent = CartReminderSweep.run
      redirect_to admin_cart_reminders_path, notice: "#{sent} reminder#{'s' unless sent == 1} sent"
    end

    # Sends a sample reminder to the studio address so the email can be checked.
    def preview
      to = NotificationSetting.instance.studio_email
      return redirect_to(admin_cart_reminders_path, alert: "Set your email in Admin → Emails first.") if to.blank?
      return redirect_to(admin_cart_reminders_path, alert: "Email sending isn't set up on the server yet.") unless Notifier.configured?
      setting = CartReminderSetting.instance
      items = Product.limit(2).map { |pr| { "kind" => "product", "id" => pr.id.to_s, "variant_id" => nil, "qty" => 1 } }
      sample = CartReminder.new(email: to, name: "Bianna", items: items, token: "preview",
                                discount_percent: setting.discount_percent, eligible_keys: setting.eligible_keys_for(items),
                                expires_at: setting.valid_days.days.from_now, created_at: Time.current)
      CartReminderMailer.reminder(sample).deliver_now
      redirect_to admin_cart_reminders_path, notice: "Sample reminder sent to #{to}"
    rescue => e
      redirect_to admin_cart_reminders_path, alert: "Sending failed: #{e.message}"
    end
  end
end

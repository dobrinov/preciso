# Storefront side of cart reminders:
# - capture: the checkout form reports the email + opt-in as it is filled in;
# - back: the email's "Return to your cart" link restores the cart (and offer);
# - unsubscribe: the email's opt-out link (also one-click POST from mail apps).
class CartRemindersController < ApplicationController
  skip_forgery_protection only: :unsubscribe
  before_action { @noindex = true }

  def capture
    return head(:no_content) unless CartReminderSetting.enabled? && !admin_signed_in?
    email = params[:email].to_s.strip.downcase
    pending = CartReminder.where(sid: analytics_sid, status: "pending", order_id: nil)

    if params[:consent] != "1" || email !~ URI::MailTo::EMAIL_REGEXP || current_cart.empty?
      pending.destroy_all
      return head(:no_content)
    end
    return head(:no_content) if CartReminder.unsubscribed?(email)

    upsert_reminder(pending.first || CartReminder.new(sid: analytics_sid), email: email, name: params[:name])
    head :no_content
  end

  def back
    reminder = CartReminder.find_by!(token: params[:token])
    first_open = reminder.opened_at.nil?
    reminder.update_columns(opened_at: Time.current) if first_open
    current_cart.replace(reminder.items) if current_cart.empty? && reminder.items.present?
    record_event("reminder_open", label: reminder.offer_active? ? "#{reminder.discount_percent}% offer" : "reminder link")

    if reminder.offer_active?
      session[:reminder_token] = reminder.token
      flash[:notice] = "Welcome back — your #{reminder.discount_percent}% offer is applied until #{reminder.expires_at.strftime('%-d %B')}."
    elsif reminder.status == "sent" && reminder.discount_percent.to_i.positive?
      flash[:notice] = "Welcome back — that offer has expired, but your pieces are still here."
    end
    redirect_to current_cart.empty? ? root_path : checkout_path
  end

  def unsubscribe
    reminder = CartReminder.find_by!(token: params[:token])
    if request.post?
      CartReminder.where("lower(email) = ?", reminder.email.downcase).where(status: %w[pending sent failed])
                  .update_all(status: "unsubscribed", updated_at: Time.current)
      reminder.update_columns(status: "unsubscribed") unless reminder.status == "converted"
      return head(:ok) if params["List-Unsubscribe"].present?
      @done = true
    end
    @email = reminder.email
  end

  private

  def upsert_reminder(reminder, email:, name:)
    setting = CartReminderSetting.instance
    reminder.assign_attributes(email: email, name: name.to_s.strip.first(100).presence || reminder.name,
                               items: current_cart.snapshot, cart_total: current_cart.total)
    reminder.send_at = setting.delay_hours.hours.from_now if reminder.new_record?
    reminder.save!
  end
end

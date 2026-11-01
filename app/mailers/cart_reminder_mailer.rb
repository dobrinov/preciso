class CartReminderMailer < ApplicationMailer
  def reminder(cart_reminder)
    @reminder = cart_reminder
    @setting = CartReminderSetting.instance
    @lines = cart_reminder.lines
    @return_url = cart_reminder_return_url(cart_reminder.token)
    @unsubscribe_url = cart_reminder_unsubscribe_url(cart_reminder.token)
    @offer = cart_reminder.discount_percent.to_i.positive? && Array(cart_reminder.eligible_keys).any?
    @offer_names = @lines.select { |l| cart_reminder.eligible?(l.kind, l.id) }.map { |l| l.record.name }
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    reply_to = NotificationSetting.instance.studio_email.presence
    mail to: cart_reminder.email, subject: @setting.subject_line, **({ reply_to: } if reply_to)
  end
end

class SubscriberMailer < ApplicationMailer
  # A studio announcement to one subscriber.
  def announcement(newsletter, subscriber)
    @newsletter = newsletter
    @subscriber = subscriber
    @unsubscribe_url = subscription_unsubscribe_url(subscriber.token)
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    reply_to = NotificationSetting.instance.studio_email.presence
    mail to: subscriber.email, subject: newsletter.subject, **({ reply_to: } if reply_to)
  end
end

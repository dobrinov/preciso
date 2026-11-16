# "Keep me posted" sign-up from the footer, and the unsubscribe link in
# announcement emails (also one-click POST from mail apps).
class SubscriptionsController < ApplicationController
  skip_forgery_protection only: :unsubscribe
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { respond_signup(:error, "Too many tries — please wait a few minutes.") }
  before_action(only: :unsubscribe) { @noindex = true }

  def create
    # Honeypot: a hidden field people never see, bots fill in. Pretend it worked.
    return respond_signup(:done) if params[:website].present?

    email = params[:email].to_s.strip
    return respond_signup(:error, "Please enter a valid email address.") unless email.match?(URI::MailTo::EMAIL_REGEXP)

    if Subscriber.subscribe(email, source: "footer", sid: analytics_sid)
      record_event("subscribe", label: "footer")
      respond_signup(:done)
    else
      respond_signup(:error, "Sorry, we couldn't save that address.")
    end
  end

  def unsubscribe
    subscriber = Subscriber.find_by!(token: params[:token])
    if request.post?
      subscriber.unsubscribe!
      return head(:ok) if params["List-Unsubscribe"].present?
      @done = true
    end
    @email = subscriber.email
  end

  private

  def respond_signup(state, message = nil)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("newsletter_signup", partial: "shared/newsletter_signup", locals: { state:, message:, email: params[:email] })
      end
      format.html do
        redirect_back fallback_location: root_path,
                      **(state == :done ? { notice: "Thank you — you're on the list." } : { alert: message })
      end
    end
  end
end

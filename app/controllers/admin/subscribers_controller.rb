require "csv"

module Admin
  # Admin → Subscribers: who asked to hear about new pieces, offers and
  # events; export the list; and send them an announcement.
  class SubscribersController < BaseController
    def index
      @filter = params[:show].presence_in(%w[active unsubscribed]) || "active"
      scope = Subscriber.recent_first
      scope = @filter == "active" ? scope.active : scope.where.not(unsubscribed_at: nil)

      respond_to do |format|
        format.html do
          @subscribers = scope.limit(300)
          @counts = { "active" => Subscriber.active.count, "unsubscribed" => Subscriber.where.not(unsubscribed_at: nil).count }
          @new_this_month = Subscriber.active.where("created_at >= ?", 30.days.ago).count
          @newsletters = Newsletter.recent_first.limit(20)
          @newsletter = Newsletter.new
        end
        format.csv do
          send_data to_csv(scope), filename: "preciso-subscribers-#{Date.current}.csv", type: "text/csv"
        end
      end
    end

    def create
      if Subscriber.subscribe(params[:email], name: params[:name], source: "admin")
        redirect_to admin_subscribers_path, notice: "#{params[:email].to_s.strip.downcase} added"
      else
        redirect_to admin_subscribers_path, alert: "That doesn't look like a valid email address."
      end
    end

    def unsubscribe
      Subscriber.find(params[:id]).unsubscribe!
      redirect_back fallback_location: admin_subscribers_path, notice: "Unsubscribed"
    end

    def destroy
      Subscriber.find(params[:id]).destroy!
      redirect_back fallback_location: admin_subscribers_path, notice: "Removed"
    end

    def announce
      return redirect_to(admin_subscribers_path, alert: "Email sending isn't set up on the server yet.") unless Notifier.configured?
      count = Subscriber.active.count
      return redirect_to(admin_subscribers_path, alert: "There are no subscribers to send to yet.") if count.zero?

      newsletter = Newsletter.new(newsletter_params.merge(recipients_count: count))
      if newsletter.save
        NewsletterJob.perform_later(newsletter.id)
        redirect_to admin_subscribers_path, notice: "Sending “#{newsletter.subject}” to #{count} subscriber#{'s' unless count == 1}"
      else
        redirect_to admin_subscribers_path, alert: newsletter.errors.full_messages.to_sentence
      end
    end

    # Sends the drafted announcement to the studio address only, to check it.
    def preview
      to = NotificationSetting.instance.studio_email
      return redirect_to(admin_subscribers_path, alert: "Set your email in Admin → Emails first.") if to.blank?
      return redirect_to(admin_subscribers_path, alert: "Email sending isn't set up on the server yet.") unless Notifier.configured?
      newsletter = Newsletter.new(newsletter_params)
      return redirect_to(admin_subscribers_path, alert: newsletter.errors.full_messages.to_sentence) unless newsletter.valid?

      sample = Subscriber.new(email: to, name: "Bianna", token: "preview")
      SubscriberMailer.announcement(newsletter, sample).deliver_now
      redirect_to admin_subscribers_path, notice: "Preview sent to #{to}"
    rescue => e
      redirect_to admin_subscribers_path, alert: "Sending failed: #{e.message}"
    end

    private

    def newsletter_params
      params.require(:newsletter).permit(:subject, :body, :button_label, :button_url)
            .to_h.transform_values { |v| v.to_s.strip }
    end

    def to_csv(scope)
      CSV.generate do |csv|
        csv << %w[email name source subscribed_at unsubscribed_at]
        scope.find_each { |s| csv << [ s.email, s.name, s.source_label, s.created_at.iso8601, s.unsubscribed_at&.iso8601 ] }
      end
    end
  end
end

module Analytics
  # Everything one browser did (all events sharing a session id), in time order.
  # A journey is split into visits wherever there is a gap of 30+ minutes.
  class Journey
    VISIT_GAP = 30.minutes

    # Funnel depth, shallowest first. Reaching a step implies the earlier ones.
    STEPS = %i[visit browse piece cart checkout order].freeze
    OUTCOMES = {
      order: "Ordered", checkout: "Left at checkout", cart: "Left in cart",
      piece: "Viewed pieces", browse: "Browsed", visit: "One page"
    }.freeze
    CATALOGUE = %r{\A(shop/|sets\z|collections?\b|campaign/)}

    attr_reader :sid, :events

    def initialize(sid, events)
      @sid = sid
      @events = events.sort_by(&:occurred_at)
    end

    def label = sid.to_s.delete_prefix("s-").upcase
    def pageviews = @pageviews ||= events.select { |e| e.event_type == "pageview" }
    def first_at = events.first.occurred_at
    def last_at = events.last.occurred_at
    def user_agent = events.find { |e| e.user_agent.present? }&.user_agent
    def ip = events.find { |e| e.ip.present? }&.ip
    def device = events.find(&:device)&.device || Event.device_for(user_agent)
    def legacy? = events.any?(&:legacy)

    # A person, as far as we can tell: not a known crawler, didn't race through
    # pages faster than anyone reads, and (for new data) the page script ran.
    def human?
      return @human if defined?(@human)
      @human = events.none?(&:bot) && !racing? && (legacy? || events.any?(&:verified_at))
    end

    # Why a journey was hidden — shown on the visitor page.
    def verdict
      return "Known crawler (user agent)" if events.any?(&:bot)
      return "Opened pages faster than anyone reads" if racing?
      return "Page script never ran — likely a scraper" unless legacy? || events.any?(&:verified_at)
      legacy? ? "Recorded before verification existed; judged on user agent" : "Page script ran on #{pageviews.count(&:verified_at)} of #{pageviews.size} pages"
    end

    def racing?
      n = pageviews.size
      n >= 6 && (pageviews.last.occurred_at - pageviews.first.occurred_at) / (n - 1) < 2.5
    end

    def source
      events.find { |e| e.source.present? }&.source || (legacy? ? "Unknown" : "Direct")
    end

    def campaign = events.find { |e| e.campaign.present? }&.campaign
    def landing = pageviews.first
    def exit_page = pageviews.last

    def reached?(step) = STEPS.index(depth) >= STEPS.index(step)

    def depth
      @depth ||=
        if events.any? { |e| e.event_type == "order" } then :order
        elsif events.any? { |e| %w[checkout_submit payment_start payment_cancel].include?(e.event_type) || e.page_key == "checkout" } then :checkout
        elsif events.any? { |e| e.event_type == "add_cart" } then :cart
        elsif pageviews.any?(&:piece_key?) then :piece
        elsif pageviews.any? { |e| e.page_key.to_s.match?(CATALOGUE) } then :browse
        elsif pageviews.size > 1 then :browse
        else :visit
        end
    end

    def outcome = OUTCOMES[depth]

    # Furthest checkout step inside the checkout itself.
    def checkout_depth
      types = events.map(&:event_type)
      return 4 if types.include?("order")
      return 3 if types.include?("payment_start")
      return 2 if types.include?("checkout_submit")
      return 1 if pageviews.any? { |e| e.page_key == "checkout" }
      0
    end

    def order_numbers = events.select { |e| e.event_type == "order" }.map(&:label).uniq
    def revenue = events.select { |e| e.event_type == "order" }.sum { |e| e.total.to_i }

    def visits
      @visits ||= events.slice_when { |a, b| b.occurred_at - a.occurred_at > VISIT_GAP }.to_a
    end

    # Time on site: measured page durations where we have them, otherwise the
    # span between the first and last event of each visit.
    def seconds_on_site
      visits.sum do |v|
        measured = v.sum { |e| e.duration_ms.to_i } / 1000
        measured.positive? ? measured : (v.last.occurred_at - v.first.occurred_at).to_i
      end
    end

    # Short "where they went" line: landing → … → furthest notable step.
    def path_summary(limit = 4)
      steps = []
      events.each do |e|
        text = case e.event_type
        when "pageview" then e.label
        when "add_cart" then "Cart"
        when "checkout_submit" then "Checkout details"
        when "order" then e.label
        end
        steps << text if text && steps.last != text
      end
      steps = steps.first(1) + [ "…" ] + steps.last(limit - 1) if steps.size > limit + 1
      steps.join(" → ")
    end

    def pieces_viewed
      pageviews.select(&:piece_key?).group_by(&:page_key).map do |key, evs|
        carted = events.any? { |e| e.event_type == "add_cart" && e.page_key == key }
        { key:, name: evs.first.name.presence || evs.first.label, views: evs.size, carted: }
      end.sort_by { |p| -p[:views] }
    end
  end
end

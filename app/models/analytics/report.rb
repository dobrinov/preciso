module Analytics
  # Builds every analytics screen from the raw events in a time window. Loads
  # the window's events once and groups them into journeys in Ruby — fine for a
  # single studio's traffic, and keeps the logic in one readable place.
  class Report
    STEP_LABELS = {
      visit: "Visited", browse: "Browsed the shop", piece: "Viewed a piece",
      cart: "Added to cart", checkout: "Started checkout", order: "Ordered"
    }.freeze
    STEP_RULES = {
      visit: "Any storefront page", browse: "Shop, sets, collection or 2+ pages",
      piece: "Product or set page", cart: "Add to cart", checkout: "Checkout page",
      order: "Order placed"
    }.freeze
    CHECKOUT_STEPS = [
      [ "Opened checkout", "Checkout page" ],
      [ "Submitted details", "Order form sent" ],
      [ "Started payment", "myPOS page opened (card only)" ],
      [ "Ordered", "Order confirmed" ]
    ].freeze

    attr_reader :from

    def initialize(from:)
      @from = from
    end

    def all_journeys
      @all_journeys ||= Event.since(from).where.not(sid: nil).order(:occurred_at)
        .group_by(&:sid).map { |sid, evs| Journey.new(sid, evs) }
    end

    def journeys = @journeys ||= all_journeys.select(&:human?)
    def hidden = @hidden ||= all_journeys.reject(&:human?)
    def hidden_hits = hidden.sum { |j| j.events.size }

    def find(sid)
      evs = Event.where(sid: sid).order(:occurred_at).to_a
      evs.any? ? Journey.new(sid, evs) : nil
    end

    def summary
      n = journeys.size
      orders = journeys.count { |j| j.reached?(:order) }
      checkout = journeys.count { |j| j.reached?(:checkout) }
      {
        visitors: n,
        engaged: journeys.count { |j| j.pageviews.size > 1 },
        piece: journeys.count { |j| j.reached?(:piece) },
        cart: journeys.count { |j| j.reached?(:cart) },
        checkout:, orders:,
        revenue: journeys.sum(&:revenue),
        order_rate: checkout.positive? ? orders * 100.0 / checkout : 0
      }
    end

    # Purchase funnel: how many journeys reached each step.
    def purchase_funnel(set = journeys)
      steps = Journey::STEPS.map do |s|
        { key: s, name: STEP_LABELS[s], rule: STEP_RULES[s], count: set.count { |j| j.reached?(s) } }
      end
      with_conversion(steps)
    end

    def checkout_funnel
      set = journeys.select { |j| j.checkout_depth.positive? }
      steps = CHECKOUT_STEPS.each_with_index.map do |(name, rule), i|
        { key: :"c#{i}", name:, rule:, count: set.count { |j| j.checkout_depth >= i + 1 } }
      end
      with_conversion(steps)
    end

    def source_funnel(source)
      purchase_funnel(journeys.select { |j| j.source == source })
    end

    def by_source
      journeys.group_by(&:source).map do |name, js|
        { name:, visitors: js.size, engaged: js.count { |j| j.pageviews.size > 1 },
          piece: js.count { |j| j.reached?(:piece) }, cart: js.count { |j| j.reached?(:cart) },
          orders: js.count { |j| j.reached?(:order) } }
      end.sort_by { |r| -r[:visitors] }
    end

    def by_device
      journeys.group_by { |j| j.device || "unknown" }.map do |name, js|
        { name: name.capitalize, visitors: js.size,
          shares: %i[visit browse piece cart order].map { |s| [ s, js.count { |j| j.reached?(s) } * 100.0 / js.size ] }.to_h,
          orders: js.count { |j| j.reached?(:order) } }
      end.sort_by { |r| -r[:visitors] }
    end

    # Per day (or per week for long windows): new journeys split by outcome.
    def daily
      span = ((Time.current - from) / 1.day).ceil.clamp(1, 10_000)
      step = span > 62 ? 7 : 1
      start = (from.beginning_of_day if step == 1) || from.beginning_of_week
      buckets = []
      t = start
      while t <= Time.current
        buckets << { t:, until: t + step.days, counts: Journey::STEPS.index_with { 0 }, total: 0 }
        t += step.days
      end
      journeys.each do |j|
        b = buckets.reverse.find { |x| j.first_at >= x[:t] }
        next unless b
        b[:counts][j.depth] += 1
        b[:total] += 1
      end
      { step:, buckets: }
    end

    # Pieces: views → carts → orders, so weak product pages stand out.
    def pieces(n = 8)
      views = Hash.new(0)
      names = {}
      carts = Hash.new(0)
      journeys.each do |j|
        j.pageviews.select(&:piece_key?).each do |e|
          views[e.page_key] += 1
          names[e.page_key] ||= e.name.presence || e.label
        end
        j.events.select { |e| e.event_type == "add_cart" }.map(&:page_key).uniq.each { |k| carts[k] += 1 }
      end
      ordered = Hash.new(0)
      OrderLine.joins(:order).where(orders: { created_at: from.. }).where.not(orders: { status: "cancelled" })
        .pluck(:kind, :item_id, :order_id).uniq.each { |kind, id, _| ordered["#{kind}/#{id}"] += 1 }
      views.sort_by { |_, v| -v }.first(n).map do |key, v|
        { key:, name: names[key], views: v, carts: carts[key], orders: ordered[key] }
      end
    end

    def sources = journeys.map(&:source).uniq.sort
    def devices = journeys.filter_map(&:device).uniq.sort

    private

    def with_conversion(steps)
      steps.each_with_index do |s, i|
        prev = i.zero? ? s[:count] : steps[i - 1][:count]
        s[:pct_prev] = prev.positive? ? s[:count] * 100.0 / prev : 0
        s[:pct_top] = steps.first[:count].positive? ? s[:count] * 100.0 / steps.first[:count] : 0
        s[:dropped] = steps[i + 1] ? s[:count] - steps[i + 1][:count] : nil
      end
    end
  end
end

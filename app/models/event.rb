class Event < ApplicationRecord
  scope :since, ->(from) { where("occurred_at >= ?", from) }
  scope :pageviews, -> { where(event_type: "pageview") }
  scope :carts, -> { where(event_type: "add_cart") }
  scope :orders, -> { where(event_type: "order") }

  # ---- summary over a time window ----
  def self.summary(from)
    evs = since(from)
    visitors = evs.distinct.count(:sid)
    pageviews = evs.pageviews.count
    carts = evs.carts.count
    orders = evs.orders.count
    revenue = evs.orders.sum(:total)
    {
      pageviews:, visitors:, carts:, orders:, revenue:,
      conversion: visitors.positive? ? (orders.to_f / visitors) * 100 : 0,
    }
  end

  def self.top_pages(from, n = 6)
    since(from).pageviews.group(:page_key, :label)
      .order(Arel.sql("count(*) desc")).limit(n).count
      .map { |(key, label), count| { key:, label:, count: } }
  end

  def self.top_pieces(from, n = 6)
    since(from).pageviews.where(piece: true).group(:page_key, :name)
      .order(Arel.sql("count(*) desc")).limit(n).count
      .map { |(key, name), count| { key:, label: name, count: } }
  end

  # Page views & unique visitors per day for the last `days` days.
  def self.daily(days)
    start = Time.current.beginning_of_day
    (0...days).to_a.reverse.map do |i|
      day_start = start - i.days
      day_end = day_start + 1.day
      day_views = pageviews.where(occurred_at: day_start...day_end)
      { t: day_start, views: day_views.count, visitors: day_views.distinct.count(:sid) }
    end
  end

  def self.recent(n = 16)
    order(occurred_at: :desc).limit(n)
  end
end

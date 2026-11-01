# One row per storefront happening: a page view, a cart change, a checkout step
# or an order. Rows sharing a `sid` (the browser session) form a visitor's
# journey; Analytics::Report turns them into visitors, visits and funnels.
class Event < ApplicationRecord
  TYPES = %w[pageview add_cart remove_cart checkout_submit payment_start payment_cancel reminder_open order].freeze

  # Crawlers, link previews, SEO tools, AI fetchers and scripts. Matched against
  # the user agent; anything listed here never counts as a visitor.
  BOT_UA = /bot|crawl|spider|slurp|externalhit|externalagent|meta-external|facebookcatalog|gpt|claude|anthropic|oai-search|chatgpt|perplexity|bytespider|petal|sogou|yandex|baidu|ahrefs|semrush|seranking|mj12|dotbot|python|curl|wget|go-http|java\/|okhttp|axios|node-fetch|headless|phantom|scrapy|httpclient|libwww|preview|monitor|uptime|lighthouse|pingdom/i

  scope :since, ->(from) { where("occurred_at >= ?", from) }
  scope :pageviews, -> { where(event_type: "pageview") }
  scope :orders, -> { where(event_type: "order") }
  scope :not_bots, -> { where(bot: false) }

  def self.bot_agent?(ua)
    ua.blank? || ua.match?(BOT_UA)
  end

  def self.device_for(ua)
    case ua.to_s
    when /iPad|Tablet|Android(?!.*Mobile)/ then "tablet"
    when /iPhone|iPod|Android|Mobile|Windows Phone/ then "phone"
    when "" then nil
    else "desktop"
    end
  end

  # Where a visit came from: utm_source wins, then the referring site, then the
  # Instagram / Facebook in-app browsers (they often send no referrer). Returns
  # nil for navigation inside the shop itself.
  def self.source_for(referrer:, utm_source:, user_agent:, own_host:)
    return label_source(utm_source) if utm_source.present?
    host = (URI.parse(referrer).host.to_s.downcase rescue "") if referrer.present?
    if host.present?
      return nil if host == own_host.to_s.downcase || host.end_with?(".#{own_host.to_s.downcase.delete_prefix('www.')}") ||
                    host.delete_prefix("www.") == own_host.to_s.downcase.delete_prefix("www.")
      return label_source(host)
    end
    return "Instagram" if user_agent.to_s.include?("Instagram")
    return "Facebook" if user_agent.to_s.match?(/FBAN|FBAV|FB_IAB/)
    "Direct"
  end

  def self.label_source(s)
    case s.to_s.downcase
    when /instagram|^ig$/ then "Instagram"
    when /facebook|fb\.|^fb$|^m\.me$/ then "Facebook"
    when /google/ then "Google"
    when /bing|duckduckgo|yahoo|yandex|ecosia|brave/ then "Other search"
    when /chatgpt|openai|perplexity|claude|gemini|copilot/ then "AI assistants"
    when /pinterest/ then "Pinterest"
    when /tiktok/ then "TikTok"
    when /mail|newsletter/ then "Email"
    else s.to_s.delete_prefix("www.").presence || "Direct"
    end
  end

  def piece_key? = page_key.to_s.match?(%r{\A(product|set)/})
end

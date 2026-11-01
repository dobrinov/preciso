# Singleton settings for abandoned-cart reminder emails (Admin → Cart reminders).
class CartReminderSetting < ApplicationRecord
  APPLIES_TO = { "all" => "Every piece and set", "selected" => "Only the pieces and sets I pick" }.freeze
  DEFAULT_SUBJECT = "You left something at Preciso"
  DEFAULT_MESSAGE = "Your pieces are still waiting for you. Come back and finish your order whenever you're ready."

  serialize :item_keys, type: Array, coder: JSON

  validates :delay_hours, numericality: { only_integer: true, in: 1..720 }
  validates :discount_percent, numericality: { only_integer: true, in: 0..90 }
  validates :valid_days, numericality: { only_integer: true, in: 1..90 }
  validates :min_cart_total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :applies_to, inclusion: { in: APPLIES_TO.keys }

  def self.instance = first || create!
  def self.enabled? = instance.enabled

  def subject_line = subject.presence || DEFAULT_SUBJECT
  def message_text = message.presence || DEFAULT_MESSAGE

  # Item keys ("product/3", "set/1") the discount applies to, from a cart snapshot.
  def eligible_keys_for(items)
    keys = items.map { |i| "#{i['kind']}/#{i['id']}" }.uniq
    applies_to == "all" ? keys : keys & Array(item_keys)
  end
end

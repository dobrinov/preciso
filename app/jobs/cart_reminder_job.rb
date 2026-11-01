# Sends every cart reminder that is due (see CartReminderSweep).
class CartReminderJob < ApplicationJob
  queue_as :default

  def perform = CartReminderSweep.run
end

# Richer analytics: where a visit came from, what device, whether it was a bot,
# and whether the page script confirmed a real browser (verified_at).
class AddJourneyFieldsToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :referrer, :string
    add_column :events, :source, :string
    add_column :events, :campaign, :string
    add_column :events, :device, :string
    add_column :events, :bot, :boolean, default: false, null: false
    add_column :events, :verified_at, :datetime
    add_column :events, :duration_ms, :integer
    add_column :events, :qty, :integer
    # Rows recorded before the page beacon existed can't be verified; they are
    # judged on user agent alone.
    add_column :events, :legacy, :boolean, default: false, null: false
    add_index :events, :sid
    add_index :events, [ :event_type, :occurred_at ]

    # Classify the history we already have so old numbers stop counting crawlers.
    Event.reset_column_information
    Event.find_each do |e|
      bot = Event.bot_agent?(e.user_agent)
      e.update_columns(bot: bot, device: Event.device_for(e.user_agent), legacy: true)
    end
  end

  def down
    remove_index :events, [ :event_type, :occurred_at ]
    remove_index :events, :sid
    %i[referrer source campaign device bot verified_at duration_ms qty legacy].each { |c| remove_column :events, c }
  end
end

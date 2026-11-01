# Abandoned-cart reminders: one settings row, and one row per shopper who gave
# their email at checkout (and opted in) but hasn't finished ordering.
class CreateCartReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_reminder_settings do |t|
      t.boolean :enabled, default: false, null: false
      t.integer :delay_hours, default: 24, null: false
      t.integer :discount_percent, default: 10, null: false
      t.integer :valid_days, default: 7, null: false
      t.string :applies_to, default: "all", null: false
      t.text :item_keys
      t.integer :min_cart_total, default: 0, null: false
      t.string :subject
      t.text :message
      t.timestamps
    end

    create_table :cart_reminders do |t|
      t.string :token, null: false
      t.string :sid
      t.string :email, null: false
      t.string :name
      t.text :items
      t.integer :cart_total, default: 0, null: false
      t.references :order, foreign_key: { on_delete: :nullify }
      t.string :status, default: "pending", null: false
      t.datetime :send_at, null: false
      t.datetime :sent_at
      t.datetime :opened_at
      t.datetime :expires_at
      t.integer :discount_percent
      t.text :eligible_keys
      t.integer :used_order_id
      t.string :detail
      t.timestamps
    end
    add_index :cart_reminders, :token, unique: true
    add_index :cart_reminders, :email
    add_index :cart_reminders, :sid
    add_index :cart_reminders, [ :status, :send_at ]
  end
end

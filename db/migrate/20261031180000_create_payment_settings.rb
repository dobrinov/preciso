class CreatePaymentSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_settings do |t|
      # Off by default: card payments only start once the studio switches them on.
      t.boolean :card_payments, null: false, default: false
      t.timestamps
    end
  end
end

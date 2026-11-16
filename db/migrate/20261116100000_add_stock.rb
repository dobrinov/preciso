# Stock: how many of a piece / variation / set the studio has ready to ship.
# nil or 0 = made to order (shoppers "Request" it); the number itself is never
# shown on the storefront.
class AddStock < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :stock, :integer
    add_column :variants, :stock, :integer
    add_column :product_sets, :stock, :integer

    # Snapshot per order line: was it ready to ship when ordered?
    add_column :order_lines, :from_stock, :boolean, default: false, null: false
    # Set once the order's in-stock lines have been taken off the counts, so it
    # happens once (and can be put back if the order is cancelled).
    add_column :orders, :stock_taken_at, :datetime

    create_table :lead_times do |t|
      t.string :ready_note
      t.string :made_note
      t.timestamps
    end
  end
end

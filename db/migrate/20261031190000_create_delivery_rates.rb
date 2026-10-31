class CreateDeliveryRates < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_rates do |t|
      t.string :country_code, null: false
      t.integer :cost, null: false, default: 0
      t.timestamps
    end
    add_index :delivery_rates, :country_code, unique: true

    # Where the order ships and what delivery cost (nil = no set price for that
    # country; the studio quotes it by hand).
    add_column :orders, :country_code, :string
    add_column :orders, :country_name, :string
    add_column :orders, :delivery_cost, :integer
  end
end

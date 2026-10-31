# One fixed price per country → several delivery options per country, each with
# a name, a type (to an address / to a courier office), a price and a note.
class DeliveryOptions < ActiveRecord::Migration[8.1]
  def change
    remove_index :delivery_rates, :country_code, unique: true
    rename_table :delivery_rates, :delivery_options
    add_index :delivery_options, :country_code
    add_column :delivery_options, :name, :string, null: false, default: "Delivery"
    add_column :delivery_options, :kind, :string, null: false, default: "address"
    add_column :delivery_options, :note, :string
    add_column :delivery_options, :position, :integer, null: false, default: 0

    # What the customer chose (snapshotted like prices).
    add_column :orders, :delivery_option_name, :string
    add_column :orders, :delivery_kind, :string # "address" | "office"
    add_column :orders, :delivery_office, :string
  end
end

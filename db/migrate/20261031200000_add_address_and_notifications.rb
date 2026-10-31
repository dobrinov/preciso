class AddAddressAndNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :address_line, :string
    add_column :orders, :city, :string
    add_column :orders, :postal_code, :string

    create_table :notification_settings do |t|
      t.string :studio_email # where "new order" / "payment received" emails go
      t.timestamps
    end
  end
end

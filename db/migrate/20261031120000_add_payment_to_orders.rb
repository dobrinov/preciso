class AddPaymentToOrders < ActiveRecord::Migration[8.1]
  def change
    # "none" = no online payment (orders placed before myPOS, or with myPOS off).
    add_column :orders, :payment_status, :string, null: false, default: "none"
    add_column :orders, :payment_reference, :string
    add_column :orders, :payment_details, :string
    add_column :orders, :paid_at, :datetime
    add_index :orders, :payment_status
  end
end

# Orders whose delivery the studio quotes by hand (no set rate for the
# country): the studio confirms the delivery cost in admin and emails the
# customer a link to pay by card.
class AddPaymentLinkToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :quote_note, :text
    add_column :orders, :payment_link_sent_at, :datetime
  end
end

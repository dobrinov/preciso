class AddScopeToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :all_products, :boolean, null: false, default: false
    add_column :campaigns, :percent_off, :integer
  end
end

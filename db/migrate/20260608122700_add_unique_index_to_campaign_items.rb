class AddUniqueIndexToCampaignItems < ActiveRecord::Migration[8.1]
  def change
    # Prevent the same catalogue item appearing twice in one campaign.
    # (The existing [kind, item_id] index still serves Campaign.discount_for.)
    add_index :campaign_items, [ :campaign_id, :kind, :item_id ], unique: true, name: "idx_campaign_items_unique"
  end
end

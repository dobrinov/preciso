class CampaignsController < ApplicationController
  def show
    @campaign = Campaign.active.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @campaign

    @records = if @campaign.all_products?
      Product.order(:id).to_a + ProductSet.order(:id).to_a
    else
      @campaign.campaign_items.filter_map(&:record)
    end
    track("campaign/#{@campaign.slug}", "Campaign · #{@campaign.name}")
  end
end

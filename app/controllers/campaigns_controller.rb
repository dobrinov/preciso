class CampaignsController < ApplicationController
  def show
    @campaign = Campaign.active.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @campaign

    @records = @campaign.campaign_items.filter_map(&:record)
    track("campaign/#{@campaign.slug}", "Campaign · #{@campaign.name}")
  end
end

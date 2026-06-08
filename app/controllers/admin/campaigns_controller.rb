module Admin
  class CampaignsController < BaseController
    before_action :set_campaign, only: [ :edit, :update, :destroy ]

    def index
      @campaigns = Campaign.all.includes(:campaign_items)
    end

    def new
      @campaign = Campaign.new
    end

    def create
      @campaign = Campaign.new(campaign_params)
      if @campaign.save
        rebuild_items(@campaign)
        attach_banner(@campaign)
        redirect_to admin_campaigns_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @campaign.update(campaign_params)
        rebuild_items(@campaign)
        attach_banner(@campaign)
        @campaign.banner.purge if params.dig(:campaign, :remove_banner) == "1"
        redirect_to admin_campaigns_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to admin_campaigns_path
    end

    private

    # Campaign#to_param is the slug, so admin URLs carry the slug in :id.
    def set_campaign
      @campaign = Campaign.find_by!(slug: params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :blurb, :active)
    end

    # params[:items] => { "product-5" => { enabled:, discount_kind:, sale_price:, percent_off: }, ... }
    # Only rows whose checkbox is enabled are kept.
    def rebuild_items(campaign)
      campaign.campaign_items.destroy_all
      Array(params[:items]).each do |key, attrs|
        next if attrs[:enabled] != "1"
        kind, id = key.split("-", 2)
        dk = attrs[:discount_kind].presence || "fixed"
        # Skip an enabled row left without its required value rather than
        # raising RecordInvalid (the model requires the value matching dk).
        value = dk == "fixed" ? attrs[:sale_price] : attrs[:percent_off]
        next if value.blank?
        campaign.campaign_items.create!(
          kind: kind, item_id: id, discount_kind: dk,
          sale_price: (dk == "fixed" ? attrs[:sale_price] : nil),
          percent_off: (dk == "percent" ? attrs[:percent_off] : nil)
        )
      end
    end

    def attach_banner(campaign)
      campaign.banner.attach(params[:campaign][:banner]) if params.dig(:campaign, :banner).present?
    end
  end
end

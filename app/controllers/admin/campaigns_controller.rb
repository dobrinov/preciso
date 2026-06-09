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
      if valid_with_items?(@campaign)
        @campaign.save!
        rebuild_items(@campaign)
        attach_banner(@campaign)
        redirect_to admin_campaigns_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @campaign.assign_attributes(campaign_params)
      if valid_with_items?(@campaign)
        @campaign.save!
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
      params.require(:campaign).permit(:name, :blurb, :active, :all_products, :percent_off)
    end

    # True only when the campaign AND its item rows are all valid. Runs the
    # model validations, then (for selection scope) flags any enabled row left
    # without its required value, so nothing is silently dropped.
    def valid_with_items?(campaign)
      campaign.percent_off = nil unless campaign.all_products?
      campaign.valid?
      add_item_errors(campaign) unless campaign.all_products?
      campaign.errors.empty?
    end

    def add_item_errors(campaign)
      params.fetch(:items, {}).each do |key, attrs|
        next if attrs[:enabled] != "1"
        dk = attrs[:discount_kind].presence || "fixed"
        value = dk == "fixed" ? attrs[:sale_price] : attrs[:percent_off]
        next if value.present?
        kind, id = key.split("-", 2)
        rec = (kind == "set" ? ProductSet : Product).find_by(id: id)
        label = rec&.name || key
        campaign.errors.add(:base, "#{label}: enter a #{dk == 'fixed' ? 'price' : 'percentage'}")
      end
    end

    # params[:items] => { "product-5" => { enabled:, discount_kind:, sale_price:, percent_off: }, ... }
    # Only rows whose checkbox is enabled are kept.
    def rebuild_items(campaign)
      campaign.campaign_items.destroy_all
      return if campaign.all_products?
      # params[:items] is ActionController::Parameters (or nil when none ticked);
      # iterate its key/value pairs directly — Array(params) would wrap it, not pair it.
      params.fetch(:items, {}).each do |key, attrs|
        next if attrs[:enabled] != "1"
        kind, id = key.split("-", 2)
        next unless CampaignItem::KINDS.include?(kind)
        next unless (kind == "set" ? ProductSet : Product).exists?(id)
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

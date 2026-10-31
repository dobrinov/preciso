module Admin
  class DeliveryRatesController < BaseController
    def index
      @rates = DeliveryRate.sorted
      @available = DeliveryRate::COUNTRIES.except(*@rates.map(&:country_code))
    end

    def create
      rate = DeliveryRate.new(country_code: params[:country_code], cost: params[:cost])
      if rate.save
        redirect_to admin_delivery_rates_path, notice: "#{rate.name} added"
      else
        redirect_to admin_delivery_rates_path, alert: rate.errors.full_messages.to_sentence
      end
    end

    def update
      rate = DeliveryRate.find(params[:id])
      if rate.update(cost: params[:cost])
        redirect_to admin_delivery_rates_path, notice: "#{rate.name} saved"
      else
        redirect_to admin_delivery_rates_path, alert: rate.errors.full_messages.to_sentence
      end
    end

    def destroy
      rate = DeliveryRate.find(params[:id])
      rate.destroy
      redirect_to admin_delivery_rates_path, notice: "#{rate.name} removed"
    end
  end
end

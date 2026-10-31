module Admin
  class DeliveryOptionsController < BaseController
    def index
      @by_country = DeliveryOption.by_country
    end

    def create
      option = DeliveryOption.new(option_params)
      option.position = DeliveryOption.where(country_code: option.country_code).maximum(:position).to_i + 1
      save_and_return(option, "#{option.name} added for #{option.country_name}")
    end

    def update
      option = DeliveryOption.find(params[:id])
      option.assign_attributes(option_params.except(:country_code))
      save_and_return(option, "#{option.name} saved")
    end

    def destroy
      option = DeliveryOption.find(params[:id])
      option.destroy
      redirect_to admin_delivery_options_path, notice: "#{option.name} (#{option.country_name}) removed"
    end

    private

    def option_params
      params.permit(:country_code, :name, :kind, :cost, :note).to_h.transform_values { |v| v.to_s.strip }
    end

    def save_and_return(option, notice)
      if option.save
        redirect_to admin_delivery_options_path, notice: notice
      else
        redirect_to admin_delivery_options_path, alert: option.errors.full_messages.to_sentence
      end
    end
  end
end

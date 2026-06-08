module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      redirect_to admin_login_path unless session[:admin]
    end

    def new_order_count
      Order.where(status: "new").count
    end
    helper_method :new_order_count
  end
end

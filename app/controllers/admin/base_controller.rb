module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    # Don't redirect to the login path — that would leak its (intentionally secret)
    # URL. Just deny with a plain message; the owner navigates to the secret URL.
    def require_admin
      return if session[:admin]
      render plain: "Access allowed only for Bibi", status: :forbidden
    end

    def new_order_count
      Order.where(status: "new").count
    end
    helper_method :new_order_count
  end
end

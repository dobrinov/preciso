module Admin
  class SessionsController < ApplicationController
    layout "admin"

    # The studio password comes from the ADMIN_PASSWORD secret (GitHub Actions
    # secret, synced to Fly). Production without it: nobody can log in.
    # Development/test fall back to "studio".
    def self.password
      ENV["ADMIN_PASSWORD"].presence || ("studio" unless Rails.env.production?)
    end

    def new
      redirect_to admin_dashboard_path if session[:admin]
    end

    def create
      expected = self.class.password
      if expected && ActiveSupport::SecurityUtils.secure_compare(params[:password].to_s, expected)
        session[:admin] = true
        redirect_to admin_dashboard_path
      else
        flash.now[:error] = "Incorrect password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin)
      redirect_to root_path
    end
  end
end

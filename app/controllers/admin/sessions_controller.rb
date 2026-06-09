module Admin
  class SessionsController < ApplicationController
    layout "admin"

    PASSWORD = "Maboardrulz9".freeze

    def new
      redirect_to admin_dashboard_path if session[:admin]
    end

    def create
      if params[:password] == PASSWORD
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

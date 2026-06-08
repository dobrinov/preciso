class SetsController < ApplicationController
  def index
    @sets = ProductSet.order(:id)
    track("sets", "Sets")
  end

  def show
    @set = ProductSet.find_by(id: params[:id])
    return render "shared/not_found", status: :not_found unless @set

    @grouped = @set.grouped_items
    track("set/#{@set.id}", @set.name, piece: true, name: "#{@set.name} (set)")
  end
end

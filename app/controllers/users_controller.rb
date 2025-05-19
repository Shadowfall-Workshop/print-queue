class UsersController < ApplicationController
  before_action :authenticate_user!

  def sync_etsy_orders
    external_account = current_user.external_accounts.find_by(provider: "etsy")

    if external_account
      service = EtsyService.new(external_account)
      service.sync_orders_to_queue_items(current_user.id)
      flash[:notice] = "Etsy orders synced successfully."
    else
      flash[:alert] = "Etsy account not connected."
    end

    redirect_to queue_items_path
  end
end
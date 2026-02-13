class UsersController < ApplicationController
  before_action :authenticate_user!

  def integrations
    render 'integrations/index'
  end
  
  def sync_single_etsy_order
    external_account = current_user.external_accounts.find_by(provider: "etsy")
    receipt_id = params[:receipt_id]

    if external_account && receipt_id
      service = EtsyService.new(external_account)
      service.sync_order_to_queue_items(current_user.id, receipt_id)
      flash[:notice] = "Etsy order synced successfully."
    else
      flash[:alert] = "Etsy account not connected or receipt ID missing."
    end

    redirect_to queue_items_path
  end

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
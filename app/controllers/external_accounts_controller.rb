class ExternalAccountsController < ApplicationController
  before_action :authenticate_user!

  def update
    external_account = current_user.external_accounts.find(params[:id])
    if external_account.update(external_account_params)
      redirect_to user_integrations_path, notice: "Saved!"
    else
      redirect_to user_integrations_path, alert: "Failed to save."
    end
  end

  private

  def external_account_params
    # permit ignored_skus_text and due_date_adjustment
    params.require(:external_account).permit(:ignored_skus_text, :due_date_adjustment)
  end
end
class AddExternalShopIdToExternalAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :external_accounts, :external_shop_id, :string
  end
end

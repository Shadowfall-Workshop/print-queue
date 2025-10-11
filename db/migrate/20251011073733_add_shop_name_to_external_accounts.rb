class AddShopNameToExternalAccounts < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up   { add_column :external_accounts, :external_shop_name, :string }
      dir.down { remove_column :external_accounts, :external_shop_name }
    end
  end
end
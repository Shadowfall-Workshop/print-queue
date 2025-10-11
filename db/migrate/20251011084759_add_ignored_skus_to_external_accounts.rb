class AddIgnoredSkusToExternalAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :external_accounts, :ignored_skus, :jsonb, default: [], null: false
  end
end

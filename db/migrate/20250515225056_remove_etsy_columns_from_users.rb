class RemoveEtsyColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :etsy_access_token, :string
    remove_column :users, :etsy_refresh_token, :string
    remove_column :users, :etsy_token_expires_at, :datetime
  end
end

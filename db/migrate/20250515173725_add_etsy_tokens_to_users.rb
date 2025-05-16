class AddEtsyTokensToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :etsy_access_token, :string
    add_column :users, :etsy_refresh_token, :string
    add_column :users, :etsy_token_expires_at, :datetime
  end
end

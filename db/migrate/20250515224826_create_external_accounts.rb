class CreateExternalAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :external_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :external_user_id
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.jsonb :metadata

      t.timestamps
    end

    # Migrate existing Etsy tokens to external_accounts
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          if user.etsy_access_token.present?
            ExternalAccount.create!(
              user_id: user.id,
              provider: "etsy",
              access_token: user.etsy_access_token,
              refresh_token: user.etsy_refresh_token,
              token_expires_at: user.etsy_token_expires_at
            )
          end
        end
      end
    end
  end
end
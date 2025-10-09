class CreateLoginTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :login_tokens do |t|
      t.references :user, foreign_key: true, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.string :purpose # optional, for flexibility (e.g. qr_login, magic_link)

      t.timestamps
    end

    add_index :login_tokens, :token, unique: true
  end
end

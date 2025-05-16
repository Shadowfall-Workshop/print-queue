class CreateSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sync_logs do |t|
      t.references :external_account, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at
      t.text :message
      t.jsonb :metadata

      t.timestamps
    end
  end
end

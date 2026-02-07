class AddDueDateAdjustmentToExternalAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :external_accounts, :due_date_adjustment, :smallint, null: false, default: 0
  end
end

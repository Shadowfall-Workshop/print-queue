class ConsolidateExternalAccountSettings < ActiveRecord::Migration[8.0]
  def change
    # Add new settings column
    add_column :external_accounts, :settings, :jsonb, default: {}

    # Migrate data from existing columns to settings
    ExternalAccount.reset_column_information
    ExternalAccount.find_each do |account|
      settings = {
        ignored_skus: account.read_attribute(:ignored_skus) || [],
        due_date_adjustment: account.read_attribute(:due_date_adjustment) || 0
      }
      account.update_column(:settings, settings)
    end

    # Remove old columns
    remove_column :external_accounts, :ignored_skus, :jsonb
    remove_column :external_accounts, :due_date_adjustment, :integer
  end
end

class SyncLog < ApplicationRecord
  has_one :external_account
  has_one :user, through: :external_account, source: :user

  #enum status: { pending: 0, success: 1, failure: 2 }

  # Convenience method to mark finished time
  def finish!(status:, message: nil, metadata: {})
    self.status = status
    self.finished_at = Time.current
    self.message = message if message
    self.metadata = metadata if metadata.present?
    save!
  end
end
class CleanupItemsJob < ApplicationJob
  queue_as :default

  def perform
    six_months_ago = 6.months.ago
    old_items = QueueItem.where("created_at < ?", six_months_ago)
    count = old_items.count

    if count.positive?
      old_items.destroy_all
      Rails.logger.info("[CleanupItemsJob] Deleted #{count} QueueItems older than 6 months.")
    else
      Rails.logger.info("[CleanupItemsJob] No old QueueItems found.")
    end
  end
end
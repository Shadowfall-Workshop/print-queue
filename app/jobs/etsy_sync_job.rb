class EtsySyncJob < ApplicationJob
  queue_as :default

  def perform
    User.joins(:external_accounts)
        .where(external_accounts: { provider: 'etsy' })
        .find_each do |user|
      external_account = user.external_accounts.find_by(provider: 'etsy')
      service = EtsyService.new(external_account)
      service.sync_orders_to_queue_items(user.id)
    end
  end
end
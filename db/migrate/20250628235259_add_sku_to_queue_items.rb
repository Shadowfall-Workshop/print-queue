class AddSkuToQueueItems < ActiveRecord::Migration[8.0]
  def change
    add_column :queue_items, :sku, :string
  end
end

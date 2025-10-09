FactoryBot.define do
  factory :queue_item do
    association :user
    name { "Test Item #{SecureRandom.hex(3)}" }
    reference_id { SecureRandom.hex(6) }
    status { QueueItem.statuses.keys.sample }
    priority { ["low", "medium", "high"].sample }
    due_date { Date.today + rand(1..30) }
    notes { "Sample notes #{SecureRandom.hex(4)}" }
    order_id { rand(1000..9999) }
    order_item_id { rand(10000..99999) }
    quantity { rand(1..5) }
    variations do
      [
        { "title" => "color", "value" => ["red","blue","green"].sample },
        { "title" => "size", "value" => ["S","M","L"].sample }
      ]
    end
    sku { SecureRandom.alphanumeric(8).upcase }
  end
end
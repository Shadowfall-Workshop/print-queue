FactoryBot.define do
  factory :sync_log do
    external_account { nil }
    status { "MyString" }
    started_at { "2025-05-15 22:48:42" }
    finished_at { "2025-05-15 22:48:42" }
    message { "MyText" }
    metadata { "" }
  end
end

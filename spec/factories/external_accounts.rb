FactoryBot.define do
  factory :external_account do
    user { nil }
    provider { "MyString" }
    external_user_id { "MyString" }
    access_token { "MyText" }
    refresh_token { "MyText" }
    token_expires_at { "2025-05-15 22:48:27" }
    metadata { "" }
  end
end

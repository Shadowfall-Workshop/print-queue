FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }

    trait :main_dev do
      email { "test@tester.test" }
      password { "Testing!" }
      password_confirmation { "password123" }
    end
  end
end
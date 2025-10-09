# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

main_user = User.find_or_create_by!(email: "test@tester.test") do |user|
  user.password = "Testing!"
  user.password_confirmation = "Testing!"
end

# Clear old QueueItems for repeatable seed
main_user.queue_items.destroy_all

# Create 150 QueueItems
150.times do
  FactoryBot.create(:queue_item, user: main_user)
end

puts "Main dev user: #{main_user.email} / Testing!"
puts "Created 150 QueueItems for #{main_user.email}"

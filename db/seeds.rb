# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
User.create!(first_name: "Don", last_name: "Garcia", email_address: "admin@example.com", password: "password")

path = "/home/wilber/MEGA/Documents/cdp/"
folders = Dir.entries(path).reject { |entry| entry.start_with?('.') }.sort

folders.each do |folder|
  file_paths = Dir.entries("#{path}/#{folder}").reject { |entry| entry.start_with?('.') || !entry.include?('-') }.sort
  file_paths.each do |file_path|
    file_path =  "#{path}/#{folder}/#{file_path}"
    puts "[CdpImporter] importando #{file_path}..."
    Importers::CdpImporter.call(file_path:)
  end
end

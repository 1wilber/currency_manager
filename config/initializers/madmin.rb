Rails.application.configure do
  Madmin.importmap = Importmap::Map.new

  Madmin.importmap.draw root.join("config/importmap.rb")
  Madmin.importmap.draw Madmin::Engine.root.join("config/importmap.rb")
end

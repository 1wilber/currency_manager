# Pin npm packages by running ./bin/importmap

pin "application", to: "application.app.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "imask", to: "https://cdn.jsdelivr.net/npm/imask@7.6.1/+esm" # @7.6.1
pin_all_from "app/javascript/controllers", under: "controllers"

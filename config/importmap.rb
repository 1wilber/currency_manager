# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "imask", to: "https://cdn.jsdelivr.net/npm/imask@7.6.1/+esm" # @7.6.1
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.12
pin "@stimulus-components/auto-submit", to: "@stimulus-components--auto-submit.js" # @6.0.0

pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
pin "flatpickr" # @4.6.13
pin "flatpickr/dist/l10n/es.js", to: "flatpickr--dist--l10n--es.js.js" # @4.6.13

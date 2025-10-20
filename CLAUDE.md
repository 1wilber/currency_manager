# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Currency Manager is a Rails 8.0 application for managing currency exchange transactions between CLP (Chilean Peso) and VES (Venezuelan Bolívar). The system tracks transactions, bank balances, customer information, and profit calculations.

## Development Commands

### Setup
```bash
bin/setup                    # Initial setup: install dependencies, setup database
bin/rails db:migrate         # Run pending migrations
bin/rails db:seed            # Seed the database
```

### Running the Application
```bash
bin/dev                      # Start development server (Rails + asset compilation)
bin/rails server             # Start Rails server only
```

### Testing
```bash
bundle exec rspec            # Run all tests
bundle exec rspec spec/path/to/file_spec.rb         # Run specific test file
bundle exec rspec spec/path/to/file_spec.rb:42      # Run test at specific line
bundle exec guard            # Run Guard for continuous testing
```

### Code Quality
```bash
bin/rubocop                  # Run RuboCop linter
bin/brakeman                 # Run security analysis
```

### Asset Building
```bash
npm run build:css            # Build Tailwind CSS
```

### Database
```bash
bin/rails db:reset           # Drop, create, migrate, and seed database
bin/rails db:rollback        # Rollback last migration
```

## Architecture

### Core Domain Models

**Transaction** - Central model representing currency exchange operations
- Polymorphic relationships: `sender` and `receiver` can be either Bank or Customer
- Automatically calculates `total` and `profit` before save
- Uses Money gem for currency handling via `has_currency_fields`
- Key fields: `amount`, `rate`, `cost_rate`, `profit`, `source_currency`, `target_currency`
- Scopes: `by_range`, `by_source_currency`, `by_target_currency`, `recents`

**Bank** - Represents financial institutions handling currencies
- Each bank has a specific `currency` (validated against `config.available_currencies`)
- Has `incomings` and `outgoings` transactions (polymorphic)
- Balance calculation: `incomings.sum(:total) - outgoings.sum(:total)`
- Special method `Bank.ves_default` for VES default bank

**BankBalance** - Tracks bank balance snapshots
- Belongs to a Bank, has many Transactions through `bank_balance_transactions`
- Calculates remaining balance after transaction allocations

**Customer** - Individuals involved in transactions
- Uses `name_of_person` gem for name handling
- Has many transactions

**User** - Authentication and authorization
- Uses bcrypt for password hashing
- Session-based authentication via `Session` model

### Key Design Patterns

**Polymorphic Associations**
- Transactions use polymorphic `sender`/`receiver` to support both Banks and Customers as endpoints
- This allows flexible transaction modeling (Bank→Bank, Bank→Customer, etc.)

**Service Objects (Interactors)**
- Uses `interactor-rails` gem for business logic encapsulation
- Example: `Importers::CdpImporter` handles Excel file imports for bulk transaction creation
- Located in `app/interactors/`

**Decorators**
- Uses Draper gem for presentation logic
- Decorators in `app/decorators/` (e.g., `TransactionDecorator`)

**Scopes with has_scope**
- Controllers use `has_scope` for query parameter filtering
- Example: `TransactionsController` filters by source/target currency and date range

### Currency Configuration

**Available Currencies**: CLP, VES (defined in `config/initializers/currency.rb`)

**Money Configuration** (`config/initializers/money.rb`):
- Default currency: CLP
- Custom currency registration for CLP and VES with specific formatting
- Rounding mode: `BigDecimal::ROUND_HALF_UP`
- Spanish locale for number formatting

### Controllers & Routes

**Main Controllers**:
- `TransactionsController` - CRUD for transactions, date range filtering
- `BanksController` - Bank listing and details
- `BankTransactionsController` - Nested transactions under banks
- `MetricsController` - Dashboard and reporting
- `Madmin::*` - Admin interface controllers

**Authentication**:
- `SessionsController` - Login/logout
- `PasswordsController` - Password reset
- `Authentication` concern - shared authentication logic

### Admin Interface

Uses Madmin gem (`app/madmin/`) for administrative features:
- Custom fields: `CurrencyField`, `LocalTimeField`, `DecimalField`
- Resources: `BankResource`, `TransactionResource`, `CustomerResource`
- Custom calculate endpoint for transactions at `madmin/transactions/calculate`

### Helpers

**MoneyHelper** - Currency formatting utilities with configurable precision (10 decimal places)
**ApplicationHelper** - Icon and flag rendering from SVG assets
**ButtonHelper** - UI component helpers (likely for form buttons/actions)

### Testing

- RSpec for testing framework
- Shoulda Matchers for validation testing
- Test types: models, controllers (requests), views, helpers, decorators, interactors
- Fixtures in `spec/fixtures/`

### Technology Stack

**Backend**:
- Rails 8.0.2, PostgreSQL, Puma
- Hotwire (Turbo, Stimulus), Importmap

**Frontend**:
- Tailwind CSS 4 + DaisyUI
- Simple Form for forms
- Chartkick + Groupdate for charts

**Background Jobs & Caching**:
- Solid Queue (jobs)
- Solid Cache (caching)
- Solid Cable (Action Cable)

**Key Gems**:
- `money-rails` - Currency handling
- `pundit` - Authorization
- `interactor-rails` - Service objects
- `draper` - Decorators
- `roo` - Excel file processing
- `has_scope` - Query filtering

### Important Conventions

**Transaction Calculation Logic**:
- `total` = `amount * rate`
- `profit` = `(amount * cost_rate - total) / rate`
- Profit margin = `profit / amount`
- All calculated automatically via `before_save` callback

**Currency Assignment**:
- Transactions auto-set `source_currency` from sender, `target_currency` from receiver
- Validation ensures both currencies are present

**Locale & Timezone**:
- Default locale: Spanish (`:es`)
- Timezone: America/Santiago

**Excel Import Format** (CdpImporter):
- Expects date in filename format: `DD-MM-YYYY.xlsx`
- Columns: Fecha, Nombre, Otro Banco, Pesos Comprados, Tasa %, Tasa Colombia
- Creates Banks and Customers automatically if they don't exist

## Development Notes

- The application uses Spanish as the default locale; translations in `config/locales/`
- Flag and icon assets are SVGs in `app/assets/flags/` and `app/assets/icons/`
- Database uses PostgreSQL with separate schemas for cache, queue, and cable
- Deployment configured with Kamal and Thruster

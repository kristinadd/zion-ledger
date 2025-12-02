# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Zion Ledger is an API-only Rails 8.1 application providing double-entry bookkeeping ledger services. The system emphasizes financial accuracy through:

- **Immutability**: Ledger entries are never modified or deleted
- **Double-entry bookkeeping**: All transactions must balance (sum to zero)
- **Precision arithmetic**: Money stored as integers (cents) in PostgreSQL bigint columns
- **ACID compliance**: All financial operations wrapped in database transactions

## Common Commands

### Setup & Development
```bash
# Initial setup (installs dependencies, creates DB, runs migrations, seeds data)
bin/setup

# Start development server
bin/dev

# Start Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Reset database (drops, creates, migrates, seeds)
bin/rails db:reset

# Prepare database (creates if missing, runs migrations)
bin/rails db:prepare
```

### Testing
```bash
# Run all tests
bin/rails test

# Run RSpec tests (uses RSpec as primary testing framework)
bundle exec rspec

# Run single test file
bundle exec rspec spec/services/balance_calculator_spec.rb

# Run specific test by line number
bundle exec rspec spec/services/balance_calculator_spec.rb:10
```

### Code Quality
```bash
# Lint with RuboCop (uses rails-omakase style)
bin/rubocop

# Auto-fix RuboCop violations
bin/rubocop -a

# Security scanning with Brakeman
bin/brakeman

# Audit gems for security vulnerabilities
bin/bundler-audit

# Run all CI checks locally
bin/ci
```

### Database
```bash
# Prepare test database
bin/rails db:test:prepare

# Annotate models with schema information
bundle exec annotaterb
```

## Architecture

### Core Domain Models

**Entry**: Individual ledger line items. Each entry has:
- `amount` (bigint): Stored in cents for precision
- `namespace` + `name`: Together form the "address" (e.g., "com.zion.account:main")
- `account_id`: Links entry to a specific customer/account
- `committed_at`: When the transaction was committed (required)
- `reporting_at`: Optional separate time axis for reporting
- `legal_entity` + `currency`: Required for each entry

**EntrySet**: Groups of entries that form a complete transaction:
- Contains multiple `Entry` records
- Must balance: `entries.sum(:amount) == 0`
- Has `idempotency_key` for duplicate prevention
- Deletes cascade to entries

### Address System

Entries are categorized using a two-part address system:
- Format: `"namespace:name"` (e.g., `"com.zion.account:main"`)
- Addresses are defined in `config/addresses.yml`
- Each address specifies which balance definitions it contributes to

### Balance Definitions

Balance calculations are configured in `config/balance_definitions.yml`:
- Defines logical groupings of addresses
- Specifies time axis (`committed_at` or `reporting_at`)
- Examples: `customer_facing_balance`, `interest_chargeable_balance`

The `BalanceCalculator` service queries entries matching the addresses configured for a given balance definition.

### Money Handling

All money amounts:
- Stored as `bigint` in database (cents)
- Converted to dollars using `amount.to_d / 100`
- Never use float arithmetic for money calculations

### API Structure

- API-only Rails app (no views)
- Versioned API under `app/controllers/api/v1/`
- Currently minimal endpoints focused on balance queries
- Routes defined with namespace structure in `config/routes.rb`

## Development Guidelines

### Adding New Addresses

1. Add address definition to `config/addresses.yml`
2. Specify namespace, name, legal entities, and currencies
3. Link to relevant balance definitions
4. No code changes needed—configuration-driven

### Adding New Balance Definitions

1. Add definition to `config/balance_definitions.yml`
2. Specify time axis and description
3. Link addresses in `config/addresses.yml` to the new balance
4. Test using `BalanceCalculator.calculate(balance_name:, account_id:)`

### Creating Transactions

Transactions must:
- Create an `EntrySet` with unique `idempotency_key`
- Create multiple `Entry` records that sum to zero
- Wrap in database transaction for atomicity
- Set `committed_at` (required) and optionally `reporting_at`

Example pattern:
```ruby
ActiveRecord::Base.transaction do
  entry_set = EntrySet.create!(
    idempotency_key: SecureRandom.uuid,
    committed_at: Time.current
  )
  
  Entry.create!(entry_set: entry_set, amount: 10000, ...) # Debit
  Entry.create!(entry_set: entry_set, amount: -10000, ...) # Credit
  
  raise "Unbalanced!" unless entry_set.balanced?
end
```

### Testing Conventions

- Uses RSpec with `factory_bot_rails` and `shoulda-matchers`
- Test files mirror source structure: `spec/services/balance_calculator_spec.rb` tests `app/services/balance_calculator.rb`
- Use factories for test data creation
- Always verify balanced entry sets in transaction tests

### Code Style

- Follows RuboCop Rails Omakase style (see `.rubocop.yml`)
- Keep methods focused and small
- Use service objects for complex business logic
- Configuration in YAML files, not code

require "rails_helper"

RSpec.describe BalanceCalculator, type: :service do
  describe ".calculate" do
    let(:account_id) { "account_123" }
    let(:entry_set) { EntrySet.create!(committed_at: Time.current, idempotency_key: SecureRandom.uuid) }

    context "with valid balance_name" do
      context "when calculating customer_facing_balance" do
        it "returns balance in dollars" do
          # Create entries for customer_facing_balance addresses
          Entry.create!(
            entry_set: entry_set,
            amount: 10000, # $100.00 in cents
            namespace: "com.zion.account",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          Entry.create!(
            entry_set: entry_set,
            amount: -2000, # -$20.00 in cents
            namespace: "com.zion.overdraft",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          result = BalanceCalculator.calculate(
            balance_name: "customer_facing_balance",
            account_id: account_id
          )

          expect(result).to eq(80.0) # $100 - $20 = $80
        end

        it "sums entries from multiple addresses" do
          Entry.create!(
            entry_set: entry_set,
            amount: 5000,
            namespace: "com.zion.account",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          Entry.create!(
            entry_set: entry_set,
            amount: 3000,
            namespace: "com.zion.overdraft",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          result = BalanceCalculator.calculate(
            balance_name: "customer_facing_balance",
            account_id: account_id
          )

          expect(result).to eq(80.0) # $50 + $30 = $80
        end

        it "excludes entries from other accounts" do
          Entry.create!(
            entry_set: entry_set,
            amount: 10000,
            namespace: "com.zion.account",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          Entry.create!(
            entry_set: entry_set,
            amount: 5000,
            namespace: "com.zion.account",
            name: "main",
            account_id: "other_account",
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          result = BalanceCalculator.calculate(
            balance_name: "customer_facing_balance",
            account_id: account_id
          )

          expect(result).to eq(100.0) # Only includes entries for account_id
        end

        it "returns zero when no entries exist" do
          result = BalanceCalculator.calculate(
            balance_name: "customer_facing_balance",
            account_id: account_id
          )

          expect(result).to eq(0.0)
        end

        it "handles negative balances" do
          Entry.create!(
            entry_set: entry_set,
            amount: -5000,
            namespace: "com.zion.account",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          result = BalanceCalculator.calculate(
            balance_name: "customer_facing_balance",
            account_id: account_id
          )

          expect(result).to eq(-50.0)
        end
      end

      context "when calculating interest_chargeable_balance" do
        it "uses committed_at time axis" do
          Entry.create!(
            entry_set: entry_set,
            amount: 10000,
            namespace: "com.zion.account",
            name: "main",
            account_id: account_id,
            legal_entity: "zion_us",
            currency: "USD",
            committed_at: Time.current
          )

          result = BalanceCalculator.calculate(
            balance_name: "interest_chargeable_balance",
            account_id: account_id
          )

          expect(result).to eq(100.0)
        end
      end
    end

    context "with invalid balance_name" do
      it "raises BalanceDefinitionNotFound error" do
        expect {
          BalanceCalculator.calculate(
            balance_name: "nonexistent_balance",
            account_id: account_id
          )
        }.to raise_error(
          BalanceCalculator::BalanceDefinitionNotFound,
          "Balance 'nonexistent_balance' not found"
        )
      end
    end

    context "with missing required parameters" do
      it "raises ArgumentError when balance_name is missing" do
        expect {
          BalanceCalculator.calculate(account_id: account_id)
        }.to raise_error(ArgumentError, /balance_name/)
      end

      it "raises ArgumentError when account_id is missing" do
        expect {
          BalanceCalculator.calculate(balance_name: "customer_facing_balance")
        }.to raise_error(ArgumentError, /account_id/)
      end
    end
  end

  describe ".available_balances" do
    it "returns list of balance definition names" do
      result = BalanceCalculator.available_balances

      expect(result).to be_an(Array)
      expect(result).to include("customer_facing_balance")
      expect(result).to include("interest_chargeable_balance")
    end

    it "returns all balance names from configuration" do
      result = BalanceCalculator.available_balances

      expect(result.length).to eq(2)
      expect(result).to match_array([
        "customer_facing_balance",
        "interest_chargeable_balance"
      ])
    end
  end
end

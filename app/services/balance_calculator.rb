# "So to calculate a balance we now:
#  1. Obtain the balance definition by looking up the provided balance identifier
#  2. Get the list of EntrySet for the balance calculation, using the list of addresses
#  3. Sum up the entries amounts (filtering by timestamps)"
#
# Usage:
#   BalanceCalculator.calculate(
#     balance_name: "customer_facing_balance",
#     account_id: 123,
#     as_of: Time.now
#   )
#   => { balance: 15000, currency: "USD", as_of: "2024-11-09T10:00:00Z" }

class BalanceCalculator
  class BalanceDefinitionNotFound < StandardError; end
  class InvalidTimeAxis < StandardError; end

  VALID_TIME_AXES = %w[committed reporting].freeze

  def self.calculate(balance_name:, account_id:, as_of: Time.current)
    new(balance_name: balance_name, account_id: account_id, as_of: as_of).calculate
  end

  def initialize(balance_name:, account_id:, as_of:)
    @balance_name = balance_name
    @account_id = account_id
    @as_of = as_of
  end

  def calculate
    definition = load_balance_definition

    addresses = fetch_addresses(definition)

    entries = fetch_entries(addresses, definition["time_axis"])

    balance = entries.sum(:amount)

    {
      balance: balance,
      balance_in_dollars: (balance.to_d / 100),
      currency: "USD", # TODO: Make this dynamic based on addresses
      as_of: as_of,
      time_axis: definition["time_axis"],
      description: definition["description"]
    }
  end

  private

  attr_reader :balance_name, :account_id, :as_of

  def load_balance_definition
    config_path = Rails.root.join("config", "balance_definitions.yml")
    config = YAML.load_file(config_path)

    definition = config["balances"][balance_name]

    unless definition
      raise BalanceDefinitionNotFound, "Balance definition '#{balance_name}' not found"
    end

    unless VALID_TIME_AXES.include?(definition["time_axis"])
      raise InvalidTimeAxis, "Invalid time_axis: #{definition['time_axis']}"
    end

    definition
  end

  def fetch_addresses(definition)
    patterns = definition["address_patterns"]

    address_ids = []

    patterns.each do |pattern|
      namespace = pattern["namespace"]
      names = pattern["names"]

      matching_addresses = Address.where(
        namespace: namespace,
        name: names,
        account_id: account_id  # Using accessor method
      )

      address_ids.concat(matching_addresses.pluck(:id))
    end

    address_ids.uniq
  end

  def fetch_entries(address_ids, time_axis)
    # Fetch entries for the addresses, filtered by time axis
    # This is the core of Monzo's approach: use the right timestamp

    entries = Entry.where(address_id: address_ids)

    case time_axis
    when "committed"
      # Use committed_at for real-time balances
      entries.where("committed_at <= ?", as_of)  # Using accessor method
    when "reporting"
      # Use reporting_at for accounting balances
      entries.where("reporting_at <= ?", as_of)  # Using accessor method
    else
      raise InvalidTimeAxis, "Unknown time_axis: #{time_axis}"
    end
  end
end

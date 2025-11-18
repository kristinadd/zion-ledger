class BalanceCalculator
  def self.available_balances
    balance_config = YAML.load_file(Rails.root.join("config/balance_definitions.yml"))

    balance_config["balance_definitions"].keys
  end

  def self.calculate(balance_name:, account_id:)
    entries = get_entries(balance_name:, account_id:)
    balance = entries.sum(&:amount)

    balance
  end

  private

  def self.get_balance_definition(balance_name)
    balance_config = YAML.load_file(Rails.root.join("config/balance_definitions.yml"))

    balance_definition = balance_config["balance_definitions"][balance_name]

    raise "Balance definition not found: #{balance_name}" if balance_definition.nil?

    balance_definition
  end

  def self.get_addresses(balance_name)
    addresses_config = YAML.load_file(Rails.root.join("config/addresses.yml"))

    addresses = addresses_config["addresses"].select do |address_key, address_data|
      address_data["balance_definitions"]&.key?(balance_name)
    end

    addresses
  end

  def self.handle_addresses(balance_name)
    addresses = get_addresses(balance_name)

    address_data = []

    addresses.each do |address_key, address_value|
      namespace = address_key.split(":")[0]
      name = address_key.split(":")[1]

      address_data << { namespace:, name: }
    end

    address_data
  end

  def self.get_entries(balance_name:, account_id:)
    address_data = get_addresses(balance_name)

    # balance_definition = get_balance_definition(balance_name)
    # time_axis = balance_definition["time_axis"]

    entries = []

    address_data.each do |address_key, address_value|
      namespace = address_key.split(":")[0]
      name = address_key.split(":")[1]

      entries << Entry.where(namespace:, name:, account_id:)
                      .where.not(committed_at: nil).to_a # TODO: fix time_axis to be dynamic (commited_at or reporting_at), not hardcoded
    end

    entries.flatten
  end
end

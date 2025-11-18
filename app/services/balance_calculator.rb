class BalanceCalculator
  def self.available_balances
    balance_config = YAML.load_file(Rails.root.join("config/balance_definitions.yml"))

    balance_config["balance_definitions"].keys
  end

  def self.calculate(balance_name)
    balance_definition = get_balance_definition(balance_name)
    addresses = get_addresses(balance_name)
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

    addresses_config["addresses"].select do |address_key, address_data|
      address_data["balance_definitions"]&.key?(balance_name)
    end
  end
end

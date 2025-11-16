class BalanceCalculator
  def self.calculate(balance_name:)
    balance_definition = get_balance_definition(balance_name:)
    # TODO: Continue implementation
  end

  private

  def self.get_balance_definition(balance_name:)
    balance_config = YAML.load_file(Rails.root.join("config/balance_definitions.yml"))

    balance_definition = balance_config["balance_definitions"][balance_name]

    raise "Balance definition not found: #{balance_name}" if balance_definition.nil?

    balance_definition
  end
end

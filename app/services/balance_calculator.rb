class BalanceCalculator
  class BalanceDefinitionNotFound < StandardError; end
  class InvalidTimeAxis < StandardError; end

  def self.available_balances
    balance_definitions_config["balance_definitions"].keys
  end

  def self.calculate(balance_name:, account_id:)
    entries = entries_for_balance(balance_name: balance_name, account_id: account_id)
    balance_in_cents = entries.sum(:amount)

    convert_to_dollars(balance_in_cents)
  end

  private

  def self.balance_definitions_config
    @balance_definitions_config ||= load_yaml_config("config/balance_definitions.yml")
  end

  def self.addresses_config
    @addresses_config ||= load_yaml_config("config/addresses.yml")
  end

  def self.load_yaml_config(relative_path)
    YAML.load_file(Rails.root.join(relative_path))
  end

  def self.balance_definition(balance_name)
    definition = balance_definitions_config["balance_definitions"][balance_name]

    raise BalanceDefinitionNotFound, "Balance '#{balance_name}' not found" if definition.nil?

    definition
  end

  def self.addresses_for_balance(balance_name)
    addresses_config["addresses"].select do |_address_key, address_data|
      address_data["balance_definitions"]&.key?(balance_name)
    end
  end

  def self.entries_for_balance(balance_name:, account_id:)
    definition = balance_definition(balance_name)
    time_axis = definition["time_axis"]
    addresses = addresses_for_balance(balance_name)

    address_components = parse_address_keys(addresses.keys)

    build_entry_query(
      address_components: address_components,
      account_id: account_id,
      time_axis: time_axis
    )
  end

  def self.parse_address_keys(address_keys)
    address_keys.map do |address_key|
      namespace, name = address_key.split(":", 2)
      [ namespace, name ]
    end
  end

  def self.build_entry_query(address_components:, account_id:, time_axis:)
    conditions = address_components.map do |namespace, name|
      base_query = Entry.where(
        namespace: namespace,
        name: name,
        account_id: account_id
      )

      apply_time_axis_filter(base_query, time_axis)
    end

    conditions.reduce(:or) || Entry.none
  end

  def self.apply_time_axis_filter(query, time_axis)
    case time_axis
    when "committed_at"
      query.where.not(committed_at: nil)
    when "reporting_at"
      query.where.not(reporting_at: nil)
    else
      raise InvalidTimeAxis, "Unknown time_axis: #{time_axis}. Must be 'committed_at' or 'reporting_at'"
    end
  end

  def self.convert_to_dollars(cents)
    cents.to_f / 100
  end
end

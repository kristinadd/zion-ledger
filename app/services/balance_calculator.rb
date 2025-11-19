class BalanceCalculator
  class << self
    def available_balances
      balance_definitions_config["balance_definitions"].keys
    end

    def calculate(balance_name:, account_id:)
      entries = get_entries(balance_name:, account_id:)
      balance = entries.sum(:amount)

      human_balance(balance)
    end

    private

    def balance_definitions_config
      @balance_definitions_config ||= YAML.load_file(Rails.root.join("config/balance_definitions.yml"))
    end

    def addresses_config
      @addresses_config ||= YAML.load_file(Rails.root.join("config/addresses.yml"))
    end

    def get_balance_definition(balance_name)
      balance_definition = balance_definitions_config["balance_definitions"][balance_name]

      raise "Balance definition not found: #{balance_name}" if balance_definition.nil?

      balance_definition
    end

    def get_addresses(balance_name)
      addresses_config["addresses"].select do |address_key, address_data|
        address_data["balance_definitions"]&.key?(balance_name)
      end
    end

    def get_entries(balance_name:, account_id:)
      balance_definition = get_balance_definition(balance_name)
      time_axis = balance_definition["time_axis"]

      address_data = get_addresses(balance_name)

      address_pairs = address_data.map do |address_key, _|
        address_key.split(":")
      end

      conditions = address_pairs.map do |namespace, name|
        base_query = Entry.where(namespace: namespace, name: name, account_id: account_id)
        apply_time_axis_filter(base_query, time_axis)
      end

      conditions.reduce(:or) || Entry.none
    end

    def apply_time_axis_filter(query, time_axis)
      case time_axis
      when "committed_at"
        query.where.not(committed_at: nil)
      when "reporting_at"
        query.where.not(reporting_at: nil)
      else
        raise "Unknown time_axis: #{time_axis}"
      end
    end

    def human_balance(balance)
      balance.to_f / 100
    end
  end
end

# Rails console script to create test addresses
# Run this in Rails console: rails console
# Then copy/paste this code

puts "Creating test addresses..."

# Account 123 - User's accounts
checking = Address.find_or_create_by!(
  namespace: "com.zion.account",
  name: "checking",
  account_id: 123
) do |addr|
  addr.currency = "USD"
end
puts "✅ Created checking address (ID: #{checking.id})"

savings = Address.find_or_create_by!(
  namespace: "com.zion.account",
  name: "savings",
  account_id: 123
) do |addr|
  addr.currency = "USD"
end
puts "✅ Created savings address (ID: #{savings.id})"

# Merchant address (no account_id - system level)
merchant = Address.find_or_create_by!(
  namespace: "com.zion.merchant",
  name: "starbucks",
  account_id: nil
) do |addr|
  addr.currency = "USD"
end
puts "✅ Created merchant address (ID: #{merchant.id})"

# Fee address (system level)
fees = Address.find_or_create_by!(
  namespace: "com.zion.fees",
  name: "transaction_fees",
  account_id: nil
) do |addr|
  addr.currency = "USD"
end
puts "✅ Created fees address (ID: #{fees.id})"

puts "\n📋 Summary:"
puts "  Checking: ID #{checking.id}"
puts "  Savings:  ID #{savings.id}"
puts "  Merchant: ID #{merchant.id}"
puts "  Fees:     ID #{fees.id}"
puts "\n✅ Ready to test entries endpoint!"

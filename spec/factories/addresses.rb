FactoryBot.define do
  factory :address do
    namespace { "com.zion.account" }
    name { "checking" }
    legal_entity { "zion_us" }
    currency { "USD" }
    account_id { 123 }
  end

  trait :merchant do
    namespace { "com.zion.merchant" }
    name { "starbucks" }
    account_id { nil }
  end
end

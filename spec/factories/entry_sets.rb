FactoryBot.define do
  factory :entry_set do
    idempotency_key { "test_#{SecureRandom.hex(8)}" }
    description { "Test transaction" }
    committed_at { Time.current }
    reporting_at { nil }

    trait :settled do
      reporting_at { Time.current }
    end

    trait :pending do
      reporting_at { nil }
    end
  end
end

FactoryBot.define do
  factory :entry do
    amount { 100 }
    committed_at { Time.current }
    reporting_at { nil }
  end
end

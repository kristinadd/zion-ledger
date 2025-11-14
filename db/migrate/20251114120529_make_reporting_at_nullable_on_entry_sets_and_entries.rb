class MakeReportingAtNullableOnEntrySetsAndEntries < ActiveRecord::Migration[8.1]
  def change
    change_column_null :entry_sets, :reporting_at, true
    change_column_null :entries, :reporting_at, true
  end
end

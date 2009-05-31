class CreateBranchPriorityCharts < ActiveRecord::Migration
  def self.up
    create_table :branch_priority_charts do |t|
      t.integer  "branch_id"
      t.integer  "priority_id"
      t.integer  "date_year"
      t.integer  "date_month"
      t.integer  "date_day"
      t.integer  "position"
      t.integer  "up_count"
      t.integer  "down_count"
      t.integer  "volume_count"
      t.float    "change_percent", :default => 0.0
      t.integer  "change",         :default => 0
      t.datetime "created_at"
    end

    add_index :branch_priority_charts, ["date_year", "date_month", "date_day"], :name => "branch_pcharts_date"
    add_index :branch_priority_charts, ["priority_id", "branch_id"], :name => "branch_pcharts_id"
    
  end

  def self.down
    drop_table :branch_priority_charts
  end
end

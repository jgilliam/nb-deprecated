class CreateBranchUserCharts < ActiveRecord::Migration
  def self.up
    create_table :branch_user_charts do |t|
      t.integer  "branch_id"      
      t.integer  "user_id"
      t.integer  "date_year"
      t.integer  "date_month"
      t.integer  "date_day"
      t.integer  "position"
      t.integer  "up_count"
      t.integer  "down_count"
      t.integer  "volume_count"
      t.datetime "created_at"
    end
    add_index :branch_user_charts, ["date_year", "date_month", "date_day"], :name => "branch_ucharts_date"
    add_index :branch_user_charts, ["user_id", "branch_id"], :name => "branch_ucharts_id"
  end

  def self.down
    drop_table :branch_user_charts
  end
end

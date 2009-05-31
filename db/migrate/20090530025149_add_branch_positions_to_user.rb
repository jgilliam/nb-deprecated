class AddBranchPositionsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :branch_position, :integer, :default => 0
    add_column :users, :branch_position_24hr, :integer, :default => 0
    add_column :users, :branch_position_7days, :integer, :default => 0
    add_column :users, :branch_position_30days, :integer, :default => 0
    add_column :users, :branch_position_24hr_change, :integer, :default => 0
    add_column :users, :branch_position_7days_change, :integer, :default => 0
    add_column :users, :branch_position_30days_change, :integer, :default => 0
    remove_column :users, :position_1hr
    remove_column :users, :position_1hr_change
  end

  def self.down
  end
end

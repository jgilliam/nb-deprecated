class AddEndorsementsCountToBranches < ActiveRecord::Migration
  def self.up
    add_column :branches, :endorsements_count, :integer, :default => 0
  end

  def self.down
  end
end

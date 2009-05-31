class CreateBranchEndorsements < ActiveRecord::Migration
  def self.up
    create_table :branch_endorsements do |t|
      t.integer :branch_id
      t.integer :priority_id
      t.integer :score, :default => 0
      t.integer :position, :default => 0
      t.integer :endorsements_count, :default => 0
      t.integer :up_endorsements_count, :default => 0
      t.integer :down_endorsements_count, :default => 0
      t.integer :position_1hr, :default => 0
      t.integer :position_24hr, :default => 0
      t.integer :position_7days, :default => 0
      t.integer :position_30days, :default => 0
      t.integer :position_1hr_change, :default => 0
      t.integer :position_24hr_change, :default => 0
      t.integer :position_7days_change, :default => 0
      t.integer :position_30days_change, :default => 0
      t.timestamps
    end
    add_index :branch_endorsements, :branch_id
    add_index :branch_endorsements, :priority_id
  end

  def self.down
    drop_table :branch_endorsements
  end
end

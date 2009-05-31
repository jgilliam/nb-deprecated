class CreateBranchPriorityRankings < ActiveRecord::Migration
  def self.up
    create_table :branch_priority_rankings do |t|
      t.integer  "branch_id"      
      t.integer  "priority_id"
      t.integer  "version",            :default => 0
      t.integer  "position"
      t.integer  "endorsements_count", :default => 0
      t.datetime "created_at"
    end
    
    add_index :branch_priority_rankings, :created_at
    add_index :branch_priority_rankings, [:priority_id, :branch_id], :name => "branch_pranks_id"
    add_index :branch_priority_rankings, :version
    Priority.connection.execute("ALTER TABLE branch_priority_rankings ENGINE=MYISAM")
  end

  def self.down
    drop_table :branch_priority_rankings
  end
end

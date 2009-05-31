class RenameBranchPriorities < ActiveRecord::Migration
  def self.up
    rename_table :branch_priority_charts, :branch_endorsement_charts
    rename_table :branch_priority_rankings, :branch_endorsement_rankings
    remove_column :branch_endorsement_charts, :branch_id
    remove_column :branch_endorsement_charts, :priority_id
    add_column :branch_endorsement_charts, :branch_endorsement_id, :integer
    add_index :branch_endorsement_charts, :branch_endorsement_id
    remove_column :branch_endorsement_rankings, :branch_id
    remove_column :branch_endorsement_rankings, :priority_id
    add_column :branch_endorsement_rankings, :branch_endorsement_id, :integer
    add_index :branch_endorsement_rankings, :branch_endorsement_id    
  end

  def self.down
  end
end

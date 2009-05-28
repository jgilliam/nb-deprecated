class CreateBranches < ActiveRecord::Migration
  def self.up
    create_table :branches do |t|
      t.string :name, :limit => 20
      t.integer :users_count, :default => 0
      t.timestamps
    end
    add_column :users, :branch_id, :integer
    add_column :governments, :default_branch_id, :integer
  end

  def self.down
    drop_table :branches
  end
end

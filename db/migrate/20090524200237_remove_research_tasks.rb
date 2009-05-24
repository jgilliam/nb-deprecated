class RemoveResearchTasks < ActiveRecord::Migration
  def self.up
    drop_table :research_tasks
  end

  def self.down
  end
end

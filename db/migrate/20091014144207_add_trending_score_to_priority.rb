class AddTrendingScoreToPriority < ActiveRecord::Migration
  def self.up
    add_column :priorities, :is_controversial, :boolean, :default => false
    add_column :priorities, :trending_score, :integer, :default => 0
    add_column :priorities, :controversial_score, :integer, :default => 0
    Priority.update_all("trending_score = 0, controversial_score = 0, is_controversial = false")
    add_index :priorities, :trending_score
  end

  def self.down
  end
end

class AddSuppressEmptyPriorities < ActiveRecord::Migration
  def self.up
    add_column :governments, :is_suppress_empty_priorities, :boolean, :default => false
  end

  def self.down
  end
end

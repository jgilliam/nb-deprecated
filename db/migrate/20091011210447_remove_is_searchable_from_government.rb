class RemoveIsSearchableFromGovernment < ActiveRecord::Migration
  def self.up
    remove_column :governments, :is_searchable
  end

  def self.down
  end
end

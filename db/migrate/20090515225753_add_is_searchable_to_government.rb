class AddIsSearchableToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :is_searchable, :boolean, :default => 0
  end

  def self.down
  end
end

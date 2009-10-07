class AddIsSearchableToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :is_searchable, :boolean, :default => false
  end

  def self.down
  end
end

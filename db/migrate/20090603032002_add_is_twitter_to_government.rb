class AddIsTwitterToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :is_twitter, :boolean, :default => true
  end

  def self.down
  end
end

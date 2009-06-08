class AddIsTwitterToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :is_twitter, :boolean, :default => 1
  end

  def self.down
  end
end

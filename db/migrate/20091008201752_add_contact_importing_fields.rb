class AddContactImportingFields < ActiveRecord::Migration
  def self.up
    add_column :users, :is_importing_contacts, :boolean, :default => false
    add_column :users, :imported_contacts_count, :integer, :default => 0
  end

  def self.down
  end
end

class AddAdminPasswordToGovt < ActiveRecord::Migration
  def self.up
    add_column :governments, :password, :string, :limit => 40
  end

  def self.down
  end
end

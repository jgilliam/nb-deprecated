class AddToUnsubscribeOptions < ActiveRecord::Migration

  def self.up
    add_column :users, :is_admin_subscribed, :boolean, :default => true
    add_column :unsubscribes, :is_admin_subscribed, :boolean, :default => false
  end

  def self.down
  end

end

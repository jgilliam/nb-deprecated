class AddToUnsubscribeOptions < ActiveRecord::Migration

  def self.up
    add_column :users, :is_admin_subscribed, :boolean, :default => 1
    add_column :unsubscribes, :is_admin_subscribed, :boolean, :default => 0
  end

  def self.down
  end

end

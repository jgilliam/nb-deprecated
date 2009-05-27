class CreateWidgets < ActiveRecord::Migration
  def self.up
    create_table :widgets do |t|
      t.integer :user_id
      t.string :tag_id
      t.string :controller_name
      t.string :action_name
      t.integer :number, :default => 5
      t.timestamps
    end
  end

  def self.down
    drop_table :widgets
  end
  
end

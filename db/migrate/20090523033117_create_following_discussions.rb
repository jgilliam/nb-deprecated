class CreateFollowingDiscussions < ActiveRecord::Migration
  def self.up
    create_table :following_discussions do |t|
      t.integer :user_id
      t.integer :activity_id
      t.timestamps
    end
    remove_column :activities, :ignorers_count
    remove_column :priorities, :search_query
    remove_column :priorities, :sphinx_index
    remove_column :points, :sphinx_index
    remove_column :documents, :sphinx_index        
    remove_column :document_qualities, :ip_address
    remove_column :point_qualities, :ip_address
    add_column :activities, :changed_at, :datetime
    remove_column :activities, :updated_at    
    add_index :activities, :changed_at
  end

  def self.down
    drop_table :following_discussions
  end
end

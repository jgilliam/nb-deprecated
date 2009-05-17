class AddCategoryDescriptions < ActiveRecord::Migration
  def self.up
    add_column :tags, :title, :string, :limit => 60
    add_column :tags, :description, :string, :limit => 200
    add_column :tags, :discussions_count, :integer, :default => 0
    add_column :tags, :points_count, :integer, :default => 0
    add_column :tags, :documents_count, :integer, :default => 0
    add_column :governments, :tags_page, :string, :limit => 20, :default => "list"
  end

  def self.down
  end
end

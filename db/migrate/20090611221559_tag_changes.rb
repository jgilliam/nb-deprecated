class TagChanges < ActiveRecord::Migration
  def self.up
    add_column :tags, :prompt, :string, :limit => 100
    add_column :tags, :slug, :string, :limit => 60
    add_index :tags, :slug
    for t in Tag.all
      t.name = t.name.titleize
      t.save_with_validation(false)
    end
    for p in Priority.all
      p.issue_list = p.issues.collect {|i|i.name}.join(', ')
      p.save_with_validation(false)
    end
    for p in Feed.all
      p.issue_list = p.issues.collect {|i|i.name}.join(', ')
      p.save_with_validation(false)
    end
    for p in Webpage.all
      p.issue_list = p.issues.collect {|i|i.name}.join(', ')
      p.save_with_validation(false)
    end    
  end

  def self.down
  end
end

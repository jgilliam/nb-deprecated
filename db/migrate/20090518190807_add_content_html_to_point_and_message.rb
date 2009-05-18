class AddContentHtmlToPointAndMessage < ActiveRecord::Migration
  def self.up
    add_column :points, :content_html, :text
    add_column :revisions, :content_html, :text
    add_column :messages, :content_html, :text
  end

  def self.down
  end
end

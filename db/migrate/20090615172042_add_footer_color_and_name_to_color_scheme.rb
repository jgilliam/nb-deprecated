class AddFooterColorAndNameToColorScheme < ActiveRecord::Migration
  def self.up
    add_column :color_schemes, :name, :string, :limit => 60
    add_column :color_schemes, :footer, :string, :limit => 6
    add_column :color_schemes, :footer_text, :string, :limit => 6
    for c in ColorScheme.all
      c.update_attribute(:footer, c.box)
      c.update_attribute(:footer_text, c.box_text)
    end
  end

  def self.down
  end
end

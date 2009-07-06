class AddTextToButtonsColorScheme < ActiveRecord::Migration
  def self.up
    add_column :color_schemes, :grey_button_text, :string, :limit => 6
    add_column :color_schemes, :action_button_text, :string, :limit => 6
    for c in ColorScheme.all
      c.update_attribute(:action_button_text, c.link) 
      c.update_attribute(:grey_button_text, c.link)       
    end
  end

  def self.down
  end
end

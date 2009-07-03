class AddLanguageCodeToGovernments < ActiveRecord::Migration
  def self.up
    add_column :governments, :language_code, :string, :limit => 2, :default => "en"
  end

  def self.down
  end
end

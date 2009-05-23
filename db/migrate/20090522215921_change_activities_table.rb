class ChangeActivitiesTable < ActiveRecord::Migration
  def self.up
    add_column :activities, :position, :integer
    add_column :activities, :followers_count, :integer, :default => 0
    add_column :activities, :ignorers_count, :integer, :default => 0
    for a in ActivityObamaLetter.find(:all)
      a.destroy
    end
    remove_column :activities, :letter_id
    remove_column :activities, :picture_id
    for a in ActivityPriorityDebut.find(:all)
      a.update_attribute(:position, a.priority_chart.position) if a.priority_chart
    end
    remove_column :activities, :priority_chart_id
    for a in ActivityUserRankingDebut.find(:all)
      a.update_attribute(:position, a.user_chart.position) if a.user_chart
    end
    remove_column :activities, :user_chart_id
  end

  def self.down
  end
end

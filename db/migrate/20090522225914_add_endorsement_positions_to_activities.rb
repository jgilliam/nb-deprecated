class AddEndorsementPositionsToActivities < ActiveRecord::Migration
  def self.up
    Activity.find_in_batches(:conditions => "endorsement_id is not null") do |activity_group|
      for a in activity_group
        a.update_attribute(:position, a.endorsement.position) if a.endorsement
      end
    end
    remove_column :activities, :endorsement_id
  end

  def self.down
  end
end

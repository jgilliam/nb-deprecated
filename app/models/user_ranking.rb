class UserRanking < ActiveRecord::Base
  
  belongs_to :user
  has_many :activities, :dependent => :nullify
  
end

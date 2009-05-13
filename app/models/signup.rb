class Signup < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :partner, :counter_cache => "users_count"
  
end

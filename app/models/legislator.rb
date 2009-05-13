class Legislator < ActiveRecord::Base
  
  named_scope :by_state, :order => "state asc, title desc, lastname asc"
  
  belongs_to :user # if they have a user account at wh2, sync it up
  
  has_many :constituents
  has_many :users, :through => :constituents
  
  def name_with_title
    title + '. ' + name
  end
  
  def lastname_with_title
    title + '. ' + lastname
  end
  
end
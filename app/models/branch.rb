class Branch < ActiveRecord::Base

  has_many :users, :dependent => :nullify

  validates_presence_of :name
  validates_length_of :name, :within => 2..20

  after_create :check_if_default_branch_exists
  
  def check_if_default_branch_exists
    Government.current.update_attribute(:default_branch_id, self.id) unless Government.current.is_branches?
  end

end

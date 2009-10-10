class LoadYahooContacts
  
  attr_accessor :id
  
  def initialize(id,path)
    @id = id
    @path = path
  end

  def perform
    Government.current = Government.all.last
    @user = User.find(@id)
    offset = 0
    if not @user.is_importing_contacts? or not @user.attribute_present?("imported_contacts_count") or @user.imported_contacts_count > 0
      @user.is_importing_contacts = true
      @user.imported_contacts_count = 0
      @user.save_with_validation(false)
    end
    yahoo = Contacts::Yahoo.new
    ycontacts = yahoo.contacts(@path)
    if ycontacts.empty?
      break 
    end
    for c in ycontacts
      begin
        if c.email
          contact = contacts.find_by_email(c.email)
          contact = contacts.new unless contact
          contact.name = c.name
          contact.email = c.email
          contact.other_user = User.find_by_email(contact.email)
          if @user.followings_count > 0 and contact.other_user
            contact.following = followings.find_by_other_user_id(contact.other_user_id)
          end
          contact.save_with_validation(false)          
          offset += 1
          @user.update_attribute(:imported_contacts_count,offset) if offset % 20 == 0        
        end
      rescue
        next
      end
    end    
    @user.calculate_contacts_count
    @user.imported_contacts_count = offset
    @user.is_importing_contacts = false
    @user.save_with_validation(false)
  end
  
end


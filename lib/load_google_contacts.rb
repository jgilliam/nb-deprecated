class LoadGoogleContacts
  
  attr_accessor :id
  
  def initialize(id)
    @id = id
  end

  def perform
    @user = User.find(@id)
    offset = 0
    if not @user.is_importing_contacts? or not @user.attribute_present?("imported_contacts_count") or @user.imported_contacts_count > 0
      @user.is_importing_contacts = true
      @user.imported_contacts_count = 0
      @user.save_with_validation(false)
    end
    gmail = Contacts::Google.new(@user.email, @user.google_token)
    gcontacts = gmail.all_contacts
    for c in gcontacts
      begin
        contact = @user.contacts.find_by_email(c.email)
        contact = @user.contacts.new unless contact
        contact.name = c.name
        contact.email = c.email
        contact.other_user = User.find_by_email(contact.email)
        if @user.followings_count > 0 and contact.other_user
          contact.following = followings.find_by_other_user_id(contact.other_user_id)
        end
        contact.save_with_validation(false)          
        offset += 1
        @user.update_attribute(:imported_contacts_count,offset) if offset % 20 == 0
      rescue
        next
      end
    end
    @user.calculate_contacts_count
    @user.imported_contacts_count = offset
    @user.is_importing_contacts = false
    @user.google_crawled_at = Time.now    
    @user.save_with_validation(false)
  end
  
end


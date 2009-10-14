namespace :pictures do  
  
  desc "import old pictures table into paperclip/s3"
  task :import => :environment do
   
   for g in Government.all
     if g.picture and not g.attribute_present?("logo_file_name")
       file_name = RAILS_ROOT + "/tmp/" + g.picture.name
       file = File.open(file_name, 'w') {|f| f.write(g.picture.data) }
       g.logo = File.new(file_name)
       File.delete(file_name)
     end
     if g.buddy_icon_old and not g.attribute_present?("buddy_icon_file_name")
       file_name = RAILS_ROOT + "/tmp/" + g.buddy_icon_old.name
       file = File.open(file_name, 'w') {|f| f.write(g.buddy_icon_old.data) }
       g.buddy_icon = File.new(file_name)
       File.delete(file_name)
     end     
     if g.fav_icon_old and not g.attribute_present?("fav_icon_file_name")
       file_name = RAILS_ROOT + "/tmp/" + g.fav_icon_old.name
       file = File.open(file_name, 'w') {|f| f.write(g.fav_icon_old.data) }
       g.fav_icon = File.new(file_name)
       File.delete(file_name)
     end
     g.save_with_validation(false)
   end

   for u in User.find(:all, :conditions => "picture_id is not null")
     if u.picture and not u.attribute_present?("buddy_icon_file_name")
       file_name = RAILS_ROOT + "/tmp/" + u.picture.name
       file = File.open(file_name, 'w') {|f| f.write(u.picture.data) }
       u.buddy_icon = File.new(file_name)
       File.delete(file_name)
       u.save_with_validation(false)
     end
   end
   
   for p in Partner.find(:all, :conditions => "picture_id is not null")
     if p.picture and not p.attribute_present?("logo_file_name")
       file_name = RAILS_ROOT + "/tmp/" + p.picture.name
       file = File.open(file_name, 'w') {|f| f.write(p.picture.data) }
       p.logo = File.new(file_name)
       File.delete(file_name)
       p.save_with_validation(false)
     end
   end   
   
  end
  
end
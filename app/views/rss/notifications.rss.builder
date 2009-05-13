xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for :controller => "inbox", :action => "notifications"
    for n in @notifications
      xml.item do
        xml.title n.name
        if n.class == NotificationComment
          xml.description render :partial => "notifications/#{n[:type].downcase}_full.html.erb", :locals => {:notification => n}
        else
          xml.description render :partial => "notifications/#{n[:type].downcase}.html.erb", :locals => {:notification => n}
        end
        xml.pubDate n.created_at.to_s(:rfc822)
        xml.author n.sender.login if n.sender
        xml.link render :partial => "notifications/#{n[:type].downcase}_link.html.erb", :locals => {:notification => n}
      end
    end
  end
end
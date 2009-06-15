xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for
    for priority in @priorities
      xml.item do
        xml.title '#' + priority.position.to_s + ' ' + priority.name
        xml.description render :partial => "priorities/show", :locals => {:priority => priority}
        xml.pubDate priority.created_at.to_s(:rfc822)
        xml.link priority_url(priority)
      end
    end
  end
end
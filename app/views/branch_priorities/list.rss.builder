xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for :format => "rss"
    for e in @priorities
      xml.item do
        xml.title '#' + e.priority.position.to_s + ' ' + e.priority.name
        xml.description render :partial => "show", :locals => {:branch_endorsement => e}
        xml.pubDate e.priority.created_at.to_s(:rfc822)
        xml.link priority_url(e.priority)
      end
    end
  end
end
xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for
    for point in @points
      xml.item do
        xml.title point.name
        xml.description render :partial => "points/show_full", :locals => {:point => point, :quality => nil, :revision => nil}
        xml.pubDate point.created_at.to_s(:rfc822)
        xml.author point.author_sentence
        xml.link point_url(point)
      end
    end
  end
end
xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for
    for activity in @activities
      xml.item do
        xml.title activity.name
        xml.pubDate activity.created_at.to_s(:rfc822)
        xml.author activity.user.login if activity.user
        xml.link activity_comments_url(activity)
      end
    end
  end
end
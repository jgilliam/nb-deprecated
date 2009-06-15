xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for :action => "discussions"
    for comment in @comments
      xml.item do
        xml.title comment.parent_name
        xml.description auto_link(simple_format(h(comment.content)))
        xml.pubDate comment.created_at.to_s(:rfc822)
        xml.author comment.user.login
        xml.link activity_comments_url(comment.activity)
      end
    end
  end
end
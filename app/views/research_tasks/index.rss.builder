xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description "Research requests submitted at " + current_government.name
    xml.link url_for :format => "rss"
    for research in @research_tasks
      xml.item do
        xml.title research.name
        xml.description simple_format(research.content)
        xml.pubDate research.created_at.to_s(:rfc822)
        xml.link url_for research
        xml.author research.requester_name_pretty
      end
    end
  end
end
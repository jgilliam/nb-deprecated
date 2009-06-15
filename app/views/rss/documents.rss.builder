xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description current_government.name_with_tagline
    xml.link url_for
    for document in @documents
      xml.item do
        xml.title document.name
        xml.description render :partial => "documents/show_full", :locals => {:document => document, :quality => nil, :revision => nil}
        xml.pubDate document.created_at.to_s(:rfc822)
        xml.author document.author_sentence
        xml.link document_url(document)
      end
    end
  end
end
class FixHelpfulCounts
  
  def perform
    Government.current = Government.all.last
    
    endorser_helpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
    FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value  =1
    and point_qualities.value = true
    group by points.id
    having number <> endorser_helpful_count")
    for point in endorser_helpful_points
      point.update_attribute("endorser_helpful_count",point.number)
    end

    endorser_helpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value  =1
    and document_qualities.value = 1
    group by documents.id
    having number <> endorser_helpful_count")
    for doc in endorser_helpful_points
      doc.update_attribute("endorser_helpful_count",doc.number)
    end    

    opposer_helpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
    FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = -1
    and point_qualities.value = true
    group by points.id
    having number <> opposer_helpful_count")
    for point in opposer_helpful_points
      point.update_attribute("opposer_helpful_count",point.number)
    end  

    opposer_helpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value = -1
    and document_qualities.value = 1
    group by documents.id
    having number <> opposer_helpful_count")
    for doc in opposer_helpful_points
      doc.update_attribute("opposer_helpful_count",doc.number)
    end    

    endorser_unhelpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
    FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = 1
    and point_qualities.value = false
    group by points.id
    having number <> endorser_unhelpful_count")
    for point in endorser_unhelpful_points
      point.update_attribute("endorser_unhelpful_count",point.number)
    end  

    endorser_unhelpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value  =1
    and document_qualities.value = 0
    group by documents.id
    having number <> endorser_unhelpful_count")
    for doc in endorser_unhelpful_points
      doc.update_attribute("endorser_unhelpful_count",doc.number)
    end    

    opposer_unhelpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
    FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = -1
    and point_qualities.value = false
    group by points.id
    having number <> opposer_unhelpful_count")
    for point in opposer_unhelpful_points
      point.update_attribute("opposer_unhelpful_count",point.number)
    end      

    opposer_unhelpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value = -1
    and document_qualities.value = 0
    group by documents.id
    having number <> opposer_unhelpful_count")
    for doc in opposer_unhelpful_points
      doc.update_attribute("opposer_unhelpful_count",doc.number)
    end  

    #neutral counts
    Point.connection.execute("update points
    set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
    neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")
    Document.connection.execute("update documents
    set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
    neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")

    Delayed::Job.enqueue FixHelpfulCounts.new, -2, 20.minutes.from_now

  end

end
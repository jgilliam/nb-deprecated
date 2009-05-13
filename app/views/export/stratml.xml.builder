xml.instruct! :xml, :version => "1.0"
xml.StrategicPlanCore :StartDate => "2008-10-19", :Date => Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s do
  xml.Submitter :Name => current_government.admin_name, :PhoneNumber => "", :EmailAddress => current_government.admin_email
  xml.Organization do
    xml.Name current_government.name
    xml.Acronym current_government.base_url
  end
  xml.Vision current_government.tagline
  xml.Mission current_government.mission
	for tag in @tags
		xml.goal do
			xml.SequenceIndicator tag.id
			xml.name tag.name.titleize
			xml.description
			for priority in tag.priorities.published.top_rank
				xml.objective do
					xml.SequenceIndicator tag.id.to_s + '.' + priority.id.to_s
					xml.name priority.name
					xml.description priority.name
					xml.otherInformation
				end
			end
		end
	end
end
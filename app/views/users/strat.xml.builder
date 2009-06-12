xml.instruct! :xml, :version => "1.0"
xml.StrategicPlanCore :StartDate => @user.created_at.year.to_s + '-' + @user.created_at.month.to_s + '-' + @user.created_at.day.to_s, :Date => Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s do
  xml.Submitter :Name => @user.name
  xml.Organization do
    xml.Name @user.name.possessive + " agenda for America"
    xml.Acronym current_government.base_url + "/users/" + @user.to_param
  end
  xml.Vision current_government.tagline
  xml.Mission current_government.mission
	for tag in @tags
		xml.goal do
			xml.SequenceIndicator tag.id
			xml.name tag.title
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
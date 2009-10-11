module FaceboxRender
   
  def render_to_facebox( options = {} )
    options[:template] = "#{default_template_name}" if options.empty?

    action_string = render_to_string(:action => options[:action], :layout => "facebox") if options[:action]
    template_string = render_to_string(:template => options[:template], :layout => "facebox") if options[:template]

    render :update do |page|
      page << "jQuery.facebox(#{action_string.to_json})" if options[:action]
      page << "jQuery.facebox(#{template_string.to_json})" if options[:template]
      page << "jQuery.facebox(#{(render :partial => options[:partial]).to_json})" if options[:partial]
      page << "jQuery.facebox(#{options[:html].to_json})" if options[:html]

      if options[:msg]
        page << "jQuery('#facebox .content').prepend('<div class=\"message\">#{options[:msg]}</div>')"
      end
      page << render(:partial => "shared/javascripts_reloadable")
      
      yield(page) if block_given?

    end
  end
    
end
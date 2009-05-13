// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
jQuery.noConflict();

jQuery(document).ready(function() {
	var isChrome = /Chrome/.test(navigator.userAgent);
	if(!isChrome & jQuery.support.opacity) {
		jQuery(".tab_header a, div.tab_body").corners(); 
	}
	jQuery("#priority_column, #intro, #buzz_box, #content_text, #notification_show, .bulletin_form").corners();
	jQuery("#top_right_column, #toolbar").corners("bottom");
	
	jQuery("abbr[class*=timeago]").timeago();	
	jQuery(":input[type=textarea]").textCounting({lengthExceededClass: 'count_over'});
	jQuery("input#priority_name").autocomplete("/priorities.js");
	jQuery("input#change_new_priority_name").autocomplete("/priorities.js");
	jQuery("input#point_other_priority_name").autocomplete("/priorities.js");
	jQuery("input#revision_other_priority_name").autocomplete("/priorities.js");
	jQuery("input#right_priority_box").autocomplete("/priorities.js");	
	jQuery("input#priority_name").DefaultValue("Suggest your priority");
	jQuery("input#q_top").DefaultValue("Search");
	jQuery("input#briefing_room_search").DefaultValue("Search talking points");
	jQuery("input#user_login_search").DefaultValue("Find a member");
	jQuery("input#right_priority_box").DefaultValue("Add a priority to your list") 

	jQuery("input#user_login_search").autocomplete("/users.js");
	jQuery("input#government_official_user_name").autocomplete("/users.js");	
	jQuery(".comment_content").truncate({max_length: 1000, more: "show full comment", less: "hide full comment"});
	jQuery(".task_content").truncate({max_length: 550, more: "show full request", less: "hide full request"});
	jQuery('#bulletin_content, #blurb_content, #message_content, #research_task_content, #document_content, #email_template_content, #page_content').autoResize({extraSpace : 20})
	
	jQuery('a#login_link').click(function() {
		jQuery('#login_form').show('fast');
	    return false;
	 });

	function addMega(){ 
	  jQuery(this).addClass("hovering"); 
	} 

	function removeMega(){ 
	  jQuery(this).removeClass("hovering"); 
	}
	var megaConfig = {
	     interval: 200,
	     sensitivity: 4,
	     over: addMega,
	     timeout: 250,
	     out: removeMega
	};
	jQuery(".mega").hoverIntent(megaConfig);

    jQuery(".flash_notice, .flash_error").fadeIn("slow");
    jQuery(".flash_notice a.close_notify").click(function() {
        jQuery(".flash_notice").fadeOut("slow");
        return false;
    });
    jQuery(".flash_error a.close_notify").click(function() {
        jQuery(".flash_error").fadeOut("slow");
        return false;
    });
	
});

function toggleAll(name)
{
  boxes = document.getElementsByClassName(name);
  for (i = 0; i < boxes.length; i++)
    if (!boxes[i].disabled)
   		{	boxes[i].checked = !boxes[i].checked ; }
}

function setAll(name,state)
{
  boxes = document.getElementsByClassName(name);
  for (i = 0; i < boxes.length; i++)
    if (!boxes[i].disabled)
   		{	boxes[i].checked = state ; }
}

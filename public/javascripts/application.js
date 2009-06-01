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
	jQuery("input#priority_name, input#change_new_priority_name, input#point_other_priority_name, input#revision_other_priority_name, input#right_priority_box").autocomplete("/priorities.js");
	jQuery("input#user_login_search, input#government_official_user_name").autocomplete("/users.js");
	jQuery('#bulletin_content, #blurb_content, #message_content, #document_content, #email_template_content, #page_content').autoResize({extraSpace : 20})
	
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
	
    jQuery('input[type="text"],input[type="password"],textarea').addClass("idleField");
	jQuery('input[type="text"],input[type="password"],textarea').focus(function() {
		jQuery(this).removeClass("idleField").addClass("focusField");
        if (this.value == this.defaultValue){
        	this.value = '';
    	}
        if(this.value != this.defaultValue){
	    	this.select();
        }
    });
    jQuery('input[type="text"],input[type="password"],textarea').blur(function() {
    	jQuery(this).removeClass("focusField").addClass("idleField");
        if (jQuery.trim(this.value == '')){
        	this.value = (this.defaultValue ? this.defaultValue : '');
    	}
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

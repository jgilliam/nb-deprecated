/*
* Rich HTML Ticker- by JavaScript Kit (http://www.javascriptkit.com)
* Freeware. Created Sept 13th, 08'
* This credit must stay intact for use
*/

var richhtmlticker={
loadingtext: '<em>Fetching Ticker Contents. Please wait...</em>', //Loading text if content is being fetched via Ajax

getajaxcontent:function($, config){
	config.$ticker.html(this.loadingtext)
	$.ajax({
		url: config.msgsource,
		error:function(ajaxrequest){
			config.$ticker.html('Error fetching content.<br />Server Response: '+ajaxrequest.responseText)
		},
		success:function(content){
			config.$ticker.html(content)
			richhtmlticker.setupticker(config)
		}
	})
},

rotate:function(config){
	if (config.$ticker.get(0)._hoverstate=="over"){
		setTimeout(function(){richhtmlticker.rotate(config)}, config.rotatespeed)
	}
	else{
		config.$messages.eq(config.currentmsg).fadeOut(config.animateduration, function(){
			config.currentmsg=(config.currentmsg<config.$messages.length-1)? config.currentmsg+1 : 0
			config.$messages.eq(config.currentmsg).fadeIn(config.animateduration, function(){
				setTimeout(function(){richhtmlticker.rotate(config)}, config.rotatespeed)
			})
		})
	}
},

getCookie:function(Name){ 
	var re=new RegExp(Name+"=[^;]+", "i") //construct RE to search for target name/value pair
	if (document.cookie.match(re)) //if cookie found
		return document.cookie.match(re)[0].split("=")[1] //return its value
	return null
},

setCookie:function(name, value){
	document.cookie = name+"="+value
},

setupticker:function(config){
	config.$messages=config.$ticker.find('div.'+config.msgclass).hide()
	config.currentmsg=Math.min(parseInt(richhtmlticker.getCookie(config.id) || 0), config.$messages.length-1)
	config.$messages.hide().eq(config.currentmsg).fadeIn(config.animateduration)
	setTimeout(function(){richhtmlticker.rotate(config)}, config.rotatespeed)
	$(window).bind('unload', function(){richhtmlticker.cleanup(config)})
},

define:function(config){
  jQuery(document).ready(function($){
		config.$ticker=$('#'+config.id)
		if (config.$ticker.length==0)
			return
		config.$ticker.css({overflow:'hidden'}).hover(
			function(){this._hoverstate="over"},
			function(){this._hoverstate="out"}
		)
		if (config.msgsource=="inline"){
			richhtmlticker.setupticker(config)
		}		
		else{
			richhtmlticker.getajaxcontent($,config)
		}
	})
},

cleanup:function(config){
	this.setCookie(config.id, config.currentmsg)
}

} //end richhtmlticker object




//////////// Declare instance of Rich HTML Ticker (invoked when page has loaded): ///////////////////////////

richhtmlticker.define({
	id: "myhtmlticker", //main ticker DIV id
	msgclass: "messagediv", //CSS class of DIVs containing each ticker message
	msgsource: "inline", //Where to look for the messages: "inline", or "path_to_file_on_your_server"
	rotatespeed: 3000, //pause in milliseconds between rotation
	animateduration: 1000 //duration of fade animation in milliseconds 
})
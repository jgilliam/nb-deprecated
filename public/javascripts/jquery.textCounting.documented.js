/** jQuery textCounting plugin
 * by Brian Swartzfager (http://www.swartzfager.org/blog/jQuery/plugins/textCounting)
 * 
 * WILL NEED TO MINIFY FROM THIS ONE
 * 
 * This is the documented version of the textCounting plugin, meant to be used as a reference guide for this plugin
 * or for testing purposes.  When you use this plugin in production, you should used the minified version
 * (jquery.textCounting.min.js).
 * 
 * --------------------------------------------------------------
 * What Does This Plugin Do
 * --------------------------------------------------------------
 * This plugin will count the number of characters or 'words' (blocks of characters separated by one or more spaces) in
 * a <textarea> every time a character is typed in the <textarea> and display either the number of words or characters in
 * the <textarea> or how many words or characters can still be typed before reaching the set limit.  It can peform this
 * operation on multiple <textarea> elements on a single page.
 * 
 * --------------------------------------------------------------
 * Default Behavior
 * --------------------------------------------------------------
 * The default behavior of the plugin is to display the number of characters left before reaching the limit (a character
 * countdown). You can use the plugin for this purpose "as is" (without specifying or changing any settings) if you follow
 * these conventions in your coding:
 * 
 * 1.  The <textarea> must have an "id" attribute with a unique value and a "maxLength" attribute with an integer denoting
 * the character limit.
 * 
 * 2.  The display element (<p>,<span>,<div>,etc.) where you want the countdown displayed must have an "id" attribute
 * whose value is the combination of the <texarea>'s "id" value and the word "Down".
 * 
 * 
 * Here's an example of a <textarea> and a <span> element that fit the convention:
 * 
 * <textarea id="comments" maxLength="1000" rows="4" cols="60"></textarea>
 * <p>Characters left: <span id="commentsDown"></span></p>
 * 
 * Because the element ids and the maxLength value is specific to each <textarea>, you can use a single call of the 
 * plugin to display a countdown for all your <textarea> elements:
 * 
 * *****************************************
 * <script language="javascript" src="jquery-1.2.3.pack.js"></script>
 * <script language="javascript" src="jquery.textCounting.min.js"></script>
 * 
 * <script language="javascript">
 * $(document).ready(function() 
 * 		$(":input[type=textarea]").textCounting();
 * });
 * </script>
 * ....
 * 
 * <textarea id="justification" maxLength="2000" rows="4" cols="60"></textarea>
 * <p>Characters left: <span id="justificationDown"></span></p>
 * 
 * <textarea id="comments" maxLength="1000" rows="4" cols="60"></textarea>
 * <p>Characters left: <span id="commentsDown"></span></p>
 * 
 * *****************************************
 * 
 * --------------------------------------------------------------
 * Plugin Settings
 * --------------------------------------------------------------
 * Like most jQuery plugins, this plugin contains a number of settings that can be configured in order to change the
 * plugin's behavior.  You can change the settings in one of three ways:
 * 
 * 1.  You can denote the settings you want in an object literal and pass that object into the plugin when you invoke it:
 * 
 * *****************************************
 * <script language="javascript">
 * var settings= {countWhat: 'words',lengthExceededClass: 'warningClass'};
 * $(":input[type=textarea]").textCounting(settings);
 * </script>
 * *****************************************
 * 
 * 2.  You can individually alter each of the 'defaults' properties of the plugin:
 * 
 * *****************************************
 * <script language="javascript">
 * $.fn.textCounting.defaults.countWhat = 'words';
 * $.fn.textCounting.defaults.lengthExceededClass = 'warningClass';
 * $(":input[type=textarea]").textCounting(settings);
 * </script>
 * *****************************************
 * 
 * 3.  If you also use the Metadata jQuery plugin (http://plugins.jquery.com/project/metadata), 
 * you can code the settings in metadata within the "class" attribute of the <textarea>:
 * 
 * *****************************************
 * <textarea class="someClass {countWhat:'words',lengthExceededClass:'warningClass'}" name="tBoxOne" id="tBoxOne"...>...
 * *****************************************
 * 
 * NOTE:  If you use the metadata method to change any settings, be aware that the changes submitted via the metadata
 * will override any settings set with the first two methods.
 * 
 * Here is a list of all of the settings and how they are used:
 * 
 * maxLengthSource
 * -----------------------
 * Possible values: "attribute", "list", "metadata"
 * Default value: "attribute"
 * 
 * The maxLengthSource setting denotes where the plugin looks for the limit value (the "maxLength") for each <textarea>.
 * The default value is "attribute," meaning that the plugin will look for the attribute in the <textarea> element whose name
 * corresponds to the value of the maxLengthAttribute plugin setting and use its value as the limit value.
 * 
 * The problem with defining a custom attribute in the <textarea> element to hold the limit value is that HTML/XHTML
 * validators will cite your web page as being invalid because custom attributes for HTML tags are currently not allowed.
 * If this kind of validity is important to you, you should use the "list" or "metadata" value for maxLengthSource.
 * 
 * If maxLengthSource is set to "list", the plugin will use the integer or comma-delimited list of integers in the 
 * maxLengthList plugin setting for the limit value (see the notes on the maxLengthList setting for more details).
 * 
 * If maxLengthSource is set to "metadata", the plugin assumes that you are using the Metadata jQuery plugin (
 * http://plugins.jquery.com/project/metadata) on the page as well, and the plugin will look for key/attribute in
 * the metadata of the <textarea> (stored in the "class" attribute of the <textarea>) whose name corresponds
 * to the value of the maxLengthAttribute plugin setting and use its value as the limit value.
 * 
 * maxLengthList
 * -------------------
 * Possible values: "" (empty), a single integer, or a comma-separated list of intergers (ex. "1000,2500,3000" )
 * Default value: ""
 * 
 * If maxLengthSource is set to "list", the plugin will use the integer or comma-delimited list of integers in the 
 * maxLengthList plugin setting for the limit value (if maxLengthList is set to "" under these conditions, a JavaScript alert
 * will appear that points out the problem).
 * 
 * Make sure you have the same number of integers in the maxLengthList value as you have <textarea> elements
 * affected by the plugin, or the wrong limit value may be associated with the wrong <textarea>
 * 
 * 
 * maxLengthAttribute
 * -----------------------
 * Possible values: a string denoting an attribute/key name, or "" (if maxLengthSource is set to "list")
 * Default value: "maxLength"
 * 
 * The value of the maxLengthAttribute setting denotes the attribute/key where the plugin will look for the character/word
 * limit. If the maxLengthSource setting is set to "attribute" or "metadata" and the maxLengthAttribute is empty, a JavaScript alert
 * will appear that points out the problem.
 * 
 * When the maxLengthSource setting is set to "attribute", the plugin will look for the attribute denoted in the value
 * of maxLength attribute within the <textarea> element itself.  When the maxLengthSource setting is set to "metadata", 
 * the plugin will look for the attribute denoted in the value of maxLength attribute within the metadata defined in the "class"
 * attribute of the <textarea>.  For example, if maxLengthSource is set to "metadata" and maxLengthAttribute is set to
 * "maxLength", the following example would work:
 * 
 * <textarea class="someClass {maxLength:'words'}" name="tBoxOne" id="tBoxOne"...>...
 * 
 * 
 * countWhat
 * --------------
 * Possible values: "characters", "words"
 * Default value: "characters"
 * 
 * The value of countWhat determines if the plugin will count either the number of characters in the <textarea> or the 
 * number of 'words' (blocks of characters separated by one or more spaces)
 * 
 * 
 * countDirection
 * ------------------
 * Possible values: "up","down","up,down" (the order doesn't matter)
 * Default value: "down"
 * 
 * The value of countWhat determines if the plugin will calculate and return the current number of characters/words in 
 * the <textarea> or if it will return the number of characters/words the user can still type before hitting the set limit.
 * You can also set the plugin to return both values, displaying the result in different elements on the page.
 * 
 * 
 * targetModifierType
 * ----------------------
 * Possible values: "prefix", "suffix", "id"
 * Default value: "suffix"
 * 
 * The "target" in the targetModifierType and targetModifier settings refers to the HTML element where the count value
 * calculated by the plugin will be displayed.  The targetModifierType setting was designed to provide an easy means of
 * associating a particular <textarea> with the HTML element or elements that will display the count value of the <textarea>.
 * 
 * If the targetModifierType is set to "suffix", the plugin will display the count value in the HTML element whose "id" attribute
 * value is the combination of the <textarea>'s "id" attribute value with the value of the targetModifier appended to the end
 * of it.  So given the following set of data:
 * 
 * <textarea> id:  "comments"
 * targetModifierType: "suffix"
 * targetModifier:  "Countdown"
 * 
 * ...the count value calculated by the plugin will be displayed in the text of the HTML element whose "id" attribute is
 * "commentsCountdown"
 * 
 * Using the same data but with targetModifierType set to "prefix" instead, the target HTML element would have an id of 
 * "Countdowncomments"
 * 
 * Using the same data but with targetModifierType set to "id" instead, the plugin will simply look for an HTML element
 * whose id equals the value of the targetModifier setting, so in this example it would simply be "Countdown".
 * 
 * You can only set targetModifierType to "id" when there is only 1 <textarea> element on the page or if you plan to 
 * define unique targetModifier settings for each separate <textarea> using metadata and the jQuery Metadata plugin:  
 * otherwise there is no means of defining unique id values for the multiple count value targets.
 * 
 * 
 * targetModifier
 * -----------------
 * Possible values: a string or a comma-separated list of strings
 * Default value: "Down"
 * 
 * See the explanation of the targetModifierType setting for information on the role of the targetModifier.  If you set the
 * countDirection setting to have the plugin calculate the count values for both "directions" ("up,down"), the targetModifier
 * will also have to be a comma-delimited list denoting where the "up" value should be displayed and where the "down" 
 * value should be displayed.
 * 
 * 
 * lengthExceededClass
 * --------------------------
 * Possible values: a string with the name of a CSS class
 * Default value: "" (empty)
 * 
 * If you want to apply a CSS class to the HTML element/elements that display the count value whenever the count value
 * has exceeded the set limit, you can provide the name of that CSS class to the lengthExceededClass setting
 * 
 * 
 * excludeIds
 * -------------
 * Possible values: a string or comma-delimited list of strings denoting <textarea> ids
 * Default value: "" (empty)
 *  
 * The excludeIds setting lets you denote any <textarea> elements you want the plugin to ignore/skip.  The use case for 
 * using this setting is when you have multiple <textarea> elements on the page and you want to apply the plugin to most
 * of those <textarea> elements with one or two exceptions.
 * 
 * Any <textarea> whose id is listed in the excludeIds setting is completely ignored by the plugin:  the count value is not
 * calculated at all and nothing is displayed.
 * 
 * 
 * --------------------------------------------------------------
 * Public Functions
 * --------------------------------------------------------------
 * This plugin contains two functions that can be called individually:
 * 
 * calculateCount(), with the parameters:
 * 		--obj: a jQuery object representing the <textarea>
 * 		--countWhat:  a string, either "characters" or "words" (not both)
 * 		--direction:  a string, either "up" or "down" (not both)
 * 		--maxCount: an integer, the limit for the characters/words in the <textarea>
 * 
 * displayResult(), with the parameters:
 * 		--obj: a jQuery object representing the <textarea>
 * 		--modifierType:  a string, either "id", "suffix", or "prefix"
 * 		--target: a string, the suffix or prefix to be combined with the <textarea>'s id to identify an HTML element
 * 		--textCount: an integer, the current number of characters/words in the <textarea>
 * 		--maxCount: an integer, the limit for the characters/words in the <textarea>
 * 		--direction:  a string, either "up" or "down" (not both)
 * 		--lengthExceededClass: a string, the name of a CSS class to apply to the HTML element defined by the target value
 * 
 * Both of these functions can be called in your JavaScript via the plugin, as shown in the example below:
 * 
 * <script language="javascript">
 * var tCount= $.fn.textCounting.calculateCount($("#tBoxOne"),'characters','down',150);
 * </script>
 */

(function($) {

	$.fn.textCounting = function(parameters) {
	
		var opts = $.extend({}, $.fn.textCounting.defaults, parameters);
		
		if (opts.maxLengthSource== "list")
			{
				if (opts.maxLengthList != "")
					{	
						var maxLengthArray= opts.maxLengthList.split(",");
						var lengthsCounter= 0;
					}
				else
					{
						denoteError("The maxLengthSource parameter of the jQuery textCounting plugin was set to 'list', but the maxLengthList parameter is blank.");
						return false;
					}
			}
	  	
	   return this.each(function() {
	   	
			var $box= $(this);
			
			//Look for the presence of the Metadata plugin and extract any metadata if needed
			var options = $.metadata ? $.extend({}, opts, $box.metadata()) : opts;
			
			var proceed= true;
			if (options.excludeIds != "")
				{
					proceed= isObjectIncluded($box.attr("id"),options.excludeIds);	
				}
		
			if (proceed)
				{	
					switch (options.maxLengthSource) 
					{
						case "list":
							var maxCount= maxLengthArray[lengthsCounter];	
							lengthsCounter++;	
							break;
						case "attribute":
							if (options.maxLengthAttribute != "")
								{
									var maxCount= $box.attr(options.maxLengthAttribute);
								}
							else
								{
									denoteError("The maxLengthSource parameter of the jQuery textCounting plugin was set to 'attribute', but the maxLengthAttribute parameter is blank.");
									return false;
								}
							break;
						case "metadata":
								if (options.maxLengthAttribute != "")
								{
									var maxCount= $box.metadata()[options.maxLengthAttribute];
									if(maxCount== undefined)
										{
											denoteError("The maxLengthAttribute specified was not found in the metadata of element " + $box.attr("id"));
											return false;
										}
								}
							else
								{
									denoteError("The maxLengthSource parameter of the jQuery textCounting plugin was set to 'metadata', but the maxLengthAttribute parameter is blank.");
									return false;
								}
							break;
					} 
									
					var directionArray= options.countDirection.split(",");
					var targetArray= options.targetModifier.split(",");
					
					for (var setting=0;setting < directionArray.length;setting++)
						{
							var currentDirection= directionArray[setting];
							var textCount= $.fn.textCounting.calculateCount($box,options.countWhat,currentDirection,maxCount);
							
							var currentTarget= targetArray[setting];
							
							$.fn.textCounting.displayResult($box,options.targetModifierType,currentTarget,textCount,maxCount,currentDirection,options.lengthExceededClass);	
									
						}
							
					$box.keyup(function () {
						for (var setting=0;setting < directionArray.length;setting++)
						{
							var currentDirection= directionArray[setting];
							var textCount= $.fn.textCounting.calculateCount($box,options.countWhat,currentDirection,maxCount);
							
							var currentTarget= targetArray[setting];
							$.fn.textCounting.displayResult($box,options.targetModifierType,currentTarget,textCount,maxCount,currentDirection,options.lengthExceededClass);		
						}		
					});
					
				} //end of proceed test
			
	   });
	};  //end of main plugin function
	
	//DEFAULTS
	$.fn.textCounting.defaults = {
		   maxLengthSource: "attribute", 
		   maxLengthList: "", 
		   maxLengthAttribute: "maxLength", 
		   countWhat: "characters",  
		   countDirection: "down", 
		   targetModifierType: "suffix",	  
		   targetModifier: "Down", 
		   lengthExceededClass: "", 
		   excludeIds: ""  
		  };
	
	//PUBLIC FUNCTIONS
	$.fn.textCounting.calculateCount = function(obj,countWhat,direction,maxCount) {
		
		if (countWhat== "characters")
			{
				if (direction== "down")
					{
						var textCount= maxCount-obj.val().length;
					}
				else
					{
						var textCount= obj.val().length;
					}
			}
		else if (countWhat== "words")
			{
				var boxText= 	jQuery.trim(obj.val());
				if(boxText != "")
					{
						var wordArray= boxText.split(/\s+/);
						if (direction== "down")
							{		
								var textCount= maxCount-wordArray.length;
							}
						else
							{
								var textCount= wordArray.length;
							}
					}
				else 
					{
						if (direction== "down")
							{		
								var textCount= maxCount;
							}
						else
							{
								var textCount= 0;	
							}
					}
			}
		return textCount;
		
	};  //end of $.fn.textCounting.calculateCount function
	
	
	$.fn.textCounting.displayResult= function(obj,modifierType,target,textCount,maxCount,direction,lengthExceededClass) {
		switch (modifierType) {
			case "id":		
				var $targetElement= $("#" +  target);
				break;
			case "prefix":
				var $targetElement= $("#" +  target + obj.attr("id"));
				break;
			case "suffix":
				var $targetElement= $("#" + obj.attr("id") + target);
				break;
		} //end of switch
		
		$targetElement.text(textCount);
		if (lengthExceededClass != "")
			{
				if((direction== 'down' && textCount < 0) || (direction== 'up' && textCount > maxCount))
					{
						$targetElement.addClass(lengthExceededClass);
					}	
				else
					{
						$targetElement.removeClass(lengthExceededClass);
					}		
			}
			
	};  //end of $.fn.textCounting.displayResult function


	//PRIVATE FUNCTIONS
	function isObjectIncluded(objId,excluded) {
			var outcome= true;
			var exclusionArray= excluded.split(",");
			for (var c= 0;c < exclusionArray.length;c++)
				{
					if (objId== exclusionArray[c])
						{
							outcome= false;
						}			
				}
			return outcome;	
		}; //end of isObjectIncluded		
		
	function denoteError(msg) {
		if(window.console) 
			{
		     	console.debug(msg);
		  	} 
		else 
			{
		     alert(msg);
		  	}
	};

})(jQuery);

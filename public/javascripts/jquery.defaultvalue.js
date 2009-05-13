jQuery.fn.DefaultValue = function(text){
    return this.each(function(){
		//Make sure we're dealing with text-based form fields
		if(this.type != 'text' && this.type != 'password' && this.type != 'textarea')
			return;
		
		//Store field reference
		var fld_current=this;
		
		//Set value initially if none are specified
        if(this.value=='') {
			this.value=text;
			jQuery(this).css({'color' : 'gray'});
		} else {
			//Other value exists - ignore
		}
		
		//Remove values on focus
		jQuery(this).focus(function() {
			if(this.value==text || this.value=='') {
				this.value='';
				jQuery(this).css({'color' : 'black'});
			}
		});
		
		//Place values back on blur
		jQuery(this).blur(function() {
			if(this.value==text || this.value=='') {
				this.value=text;
				jQuery(this).css({'color' : 'gray'});
			}
		});
		
		//Capture parent form submission
		//Remove field values that are still default
		jQuery(this).parents("form").each(function() {
			//Bind parent form submit
			jQuery(this).submit(function() {
				if(fld_current.value==text) {
					fld_current.value='';
				}
			});
		});
    });
};

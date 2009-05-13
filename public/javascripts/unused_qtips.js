
jQuery.fn.qtip.styles.bottom = { // Last part is the name of the style
	width: 180,
	background: '#ffff99',
	color: 'black',
	fontSize: '1.2em',
	textAlign: 'center',
	border: {
	   width: 2,
	   radius: 3,
	   color: '#ffcc00'
	},
	tip: { // Now an object instead of a string
		corner: 'topMiddle', // We declare our corner within the object using the corner sub-option
		size: {
		   x: 10, // Be careful that the x and y values refer to coordinates on screen, not height or width.
		   y : 5 // Depending on which corner your tooltip is at, x and y could mean either height or width!
		}
	},
	name: 'dark' // Inherit the rest of the attributes from the preset dark style
}
jQuery.fn.qtip.styles.left = { // Last part is the name of the style
	width: 200,
	background: '#ffff99',
	color: 'black',
	fontSize: '1.2em',
	textAlign: 'left',
	border: {
	   width: 2,
	   radius: 3,
	   color: '#ffcc00'
	},
	tip: { // Now an object instead of a string
		corner: 'rightMiddle', // We declare our corner within the object using the corner sub-option
		size: {
		   x: 10, // Be careful that the x and y values refer to coordinates on screen, not height or width.
		   y: 10 // Depending on which corner your tooltip is at, x and y could mean either height or width!
		}
	},
	name: 'dark' // Inherit the rest of the attributes from the preset dark style
}	
jQuery('.qtip_left').qtip({
	style: 'left',
	show: { delay: 400 },
	position: {
		corner: {
			target: 'leftMiddle',
			tooltip: 'rightMiddle'
		}
	}
})	
jQuery.fn.qtip.styles.right = { // Last part is the name of the style
	width: 200,
	background: '#ffff99',
	color: 'black',
	fontSize: '1.2em',
	textAlign: 'left',
	border: {
	   width: 2,
	   radius: 3,
	   color: '#ffcc00'
	},
	tip: { // Now an object instead of a string
		corner: 'leftMiddle', // We declare our corner within the object using the corner sub-option
		size: {
		   x: 10, // Be careful that the x and y values refer to coordinates on screen, not height or width.
		   y: 10 // Depending on which corner your tooltip is at, x and y could mean either height or width!
		}
	},
	name: 'dark' // Inherit the rest of the attributes from the preset dark style
}	
jQuery('.priority_position,.position_nochange,.position_up,.position_down').qtip({
	style: 'right',
	show: { delay: 400 },
	position: {
		corner: {
			target: 'rightMiddle',
			tooltip: 'leftMiddle'
		}
	}
})	
jQuery('a[title]').qtip({ 
	style: 'bottom',
	show: { delay: 400 },
	position: {
		corner: {
			target: 'bottomMiddle',
			tooltip: 'topMiddle'
		},
		adjust: {
			screen: true
		}
	}
})
#
# Here is an intro comment block.
# It is now two lines long.
#

package provide annotatedit 0.1
namespace eval annotatedit {

	package require Tcl 8.5
	package require Tk 8.5
	package require ctext
	package require text::sync

	# create the editor widgets
	ctext .anno -wrap none -height 20 -font TkFixedFont -highlight 0 -fg "gray" 
	ctext .code -wrap none -height 20 -font TkFixedFont -highlight 0
			
	# put the widgets in the window
	pack .anno .code -expand 1 -fill both -side left
	
	# synchronize the editor widgets
	text::sync::sync {.anno .code} -insert 1 -delete 1 -edit 1 -tag 1 -xview 1 -yview 1
	
	# for sample text, insert the contents of any files specified on the command line
	foreach arg $argv {
		
		if {![file exists $arg] || ![file isfile $arg]} {
			puts "$arg is not a file"
			continue
		}
		
		set fp [open $arg r]
	    set file_data [read $fp]
     	close $fp
		
		.code insert 1.0 $file_data
	}
	
	# Search for comment lines and tag them as ANNOtations.
	# (This assumes there was some text worth searching inserted from the CLI.)
	.code tag configure ANNO -background "light gray" 
	.anno tag configure ANNO -foreground "purple"
	variable starts {}
	variable spans {}
	
	# actually, not using -all would prob let do the search incrementally as part of
	# the tagging loop, which will also make it easy to compute the intervening spans to tag as CODE
	set starts [.code search -all -count ::annotatedit::spans -regexp {^\s#.*$} 1.0]
	
	set annoID 0
	foreach start $starts span $spans {
		# confirmed: increment span to include newline; if elided, hides line.
		.code tag add ANNO $start "$start + [incr span] indices"
		.code tag add [format "ANNO%d" [incr annoID]] $start "$start + $span indices"
		puts [format "$annoID: %s" [.code tag ranges "ANNO$annoID"]]
	}
}

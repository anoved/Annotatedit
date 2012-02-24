package provide annotatedit 0.1
namespace eval annotatedit {

	package require Tcl 8.5
	package require Tk 8.5
	package require ctext
	package require text::sync

	# create the editor widgets
	ctext .anno -wrap none -height 20 -fg "gray" 
	ctext .code -wrap none -height 20
			
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
	# Obviously, this one-time search is only feasible as an initial test.
	# This tagjob will be used to work out different tag styles for each editor.
	# (text::sync syncs tags, but we need to modify to NOT sync tag configure.)
	# Once that's sorted, we can work on tagging during insertion, updating, etc.
	.code tag configure ANNO -underline 1
	variable starts {}
	variable spans {}
	set starts [.code search -all -count ::annotatedit::spans -regexp {^\s#.*$} 1.0]
	foreach start $starts span $spans {
		.code tag add ANNO $start "$start + $span indices"
	}
	
}

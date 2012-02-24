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
}

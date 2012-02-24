#
# Here is an intro comment block.
# It is now two lines long.
# (Presently, each comment line is actually treated as a separate block.)
# 

package provide annotatedit 0.1
namespace eval annotatedit {

	package require Tcl 8.5
	package require Tk 8.5
	package require ctext
	package require text::sync

	# create the editor widgets
	ctext .anno -wrap none -height 20 -font TkFixedFont -highlight 0 -background "light gray"
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
	
	# Tag styles - these (alone) are not synced between editor widgets
	.code tag configure ANNO -foreground "red"
	.code tag configure CODE
	.anno tag configure ANNO -spacing3 16
	.anno tag configure CODE -foreground "red"
	
	# testing - click text to print associated tags
	foreach panel {.code .anno} {
		bind $panel <ButtonPress-1> {
			puts [%W tag names "@%x,%y"]
		}
	}
	
	# Used to locate search results
	variable matchStart
	variable matchSpan
	variable searchStart 1.0
	variable tagSetNumber 0
	
	#
	# This new regexp pattern matches whole comment blocks,
	# not just individual lines (as did the old pattern: {^[[:blank:]]*#.*$}).
	# Here, comment blocks are represented as comment lines preceded and
	# followed by blank lines. So, this here is a comment block. Other
	# comment lines are ignored as "inline comments" and tagged as code.
	#
	while {[set matchStart [.code search -forward -count ::annotatedit::matchSpan -regexp -- {^[[:blank:]]*#\n(?:[[:blank:]]*#.+?\n)+[[:blank:]]*#$} $searchStart end]] != {}} {
		
		# tag anything between this comment block and previous one
		# (or the file's start) as a code block
		if {$searchStart ne $matchStart} {
			.code tag add CODE $searchStart $matchStart
			.code tag add [format "CODE%d" $tagSetNumber] $searchStart $matchStart
		}		
		
		# tag this comment block
		incr tagSetNumber
		incr matchSpan
		set matchEnd [.code index "$matchStart + $matchSpan indices"]
		.code tag add ANNO $matchStart $matchEnd
		.code tag add [format "ANNO%d" $tagSetNumber] $matchStart $matchEnd
		
		# look for the next comment block beginning where this one ends
		set searchStart $matchEnd
	}
	
	# finish up by tagging anything after the last comment as a code block
	.code tag add CODE $searchStart end
	.code tag add [format "CODE%d" $tagSetNumber] $searchStart end
	
	
}

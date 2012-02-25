set startcode 34

#
# Here is an intro comment block.
# It is a couple lines long.
# More specifically, it is quite
# a bit longer than the block of
# code that follows. We need to make
# sure the right block gets padded.
# If the comment is longer, the
# following code should be bottom-padded.
# If the code is longer, the comment
# should be bottom padded.
# So why are we top-padding?
#
set shortcode 1

#
# here is another test
#
package provide annotatedit 0.1
namespace eval annotatedit {

	package require Tcl 8.5
	package require Tk 8.5
	package require ctext
	package require text::sync

	# create the editor widgets
	ctext .anno -wrap none -height 20 -width 50 -font TkFixedFont -linemap 0 -foreground "blue"
	ctext .code -wrap none -height 20 -width 50 -font TkFixedFont -linemap 0
			
	# put the widgets in the window
	pack .anno .code -expand 1 -fill both -side left
	
	# synchronize the editor widgets
	text::sync::sync {.anno .code} -insert 1 -delete 1 -edit 1 -tag 1 -xview 0 -yview 1
	
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
	.code tag configure ANNO -elide 1
	.code tag configure CODE
	.anno tag configure ANNO
	.anno tag configure CODE -elide 1
		
	proc lineOfIndex {textIndex} {
		return [lindex [split $textIndex .] 0]
	}
	
	proc blockSpan {startIndex endIndex} {
		return [expr {[lineOfIndex $endIndex] - [lineOfIndex $startIndex]}]
	}
	
	# Used to locate search results
	variable matchStart
	variable matchSpan
	variable searchStart 1.0
	variable tagSetNumber 0
	
	variable span 0
	
	variable annoHeight 0
	variable codeHeight 0
	
	#
	# Find comment blocks (comment lines immediately preceded
	# and followed by blank comments, like this).
	#
	while {[set matchStart [.code search -forward -count ::annotatedit::matchSpan -regexp -- {^[[:blank:]]*#\n(?:[[:blank:]]*#.+?\n)+[[:blank:]]*#$} $searchStart end]] != {}} {
		
		# tag anything between this comment block and previous one
		# (or the file's start) as a code block
		if {$searchStart ne $matchStart} {
			.code tag add CODE $searchStart $matchStart
			.code tag add [format "CODE%d" $tagSetNumber] $searchStart $matchStart
			
			# length of this block in lines
			.code tag add [format "CODE%dTOP" $tagSetNumber] $searchStart [format "%d.end" [lineOfIndex $searchStart]]
			.code tag configure [format "CODE%dTOP" $tagSetNumber] -spacing1 [expr {$span * 15}] -background "light gray"
			set span [blockSpan $searchStart $matchStart]
			
			# compare this span to the previous span (from the previous comment)
		}		
		
		# tag this comment block
		incr tagSetNumber
		incr matchSpan
		set matchEnd [.code index "$matchStart + $matchSpan indices"]
		.code tag add ANNO $matchStart $matchEnd
		.code tag add [format "ANNO%d" $tagSetNumber] $matchStart $matchEnd
		
# 		if commentheight > codeheight {
# 			# pad the bottom of code
# 		} elseif codeheight > commentheight {
# 			# pad the bottom of comment
# 		} else {
# 			# shouldn't need to do anything if they match
# 		}
		
		#
		# set the top spacing of this annotation block to the span of the preceding
		# code block. (funny - I was thinking of doing the spacing w/bottom spacing,
		# but top spacing seems to fit more cleanly with this loop structure.
		# only want/need to configure this padding in the anno editor
		#
		.code tag add [format "ANNO%dTOP" $tagSetNumber] $matchStart [format "%d.end" [lineOfIndex $matchStart]]
		.anno tag configure [format "ANNO%dTOP" $tagSetNumber] -spacing1 [expr {$span * 15}]
		set span [blockSpan $matchStart $matchEnd]
		
		# look for the next comment block beginning where this one ends
		set searchStart $matchEnd
	}
	
	# finish up by tagging anything after the last comment as a code block
	.code tag add CODE $searchStart end
	.code tag add [format "CODE%d" $tagSetNumber] $searchStart end
	
	.code tag add [format "CODE%dTOP" $tagSetNumber] $searchStart [format "%d.end" [lineOfIndex $searchStart]]
	.code tag configure [format "CODE%dTOP" $tagSetNumber] -spacing1 [expr {$span * 15}] -background "light gray"
	set span [blockSpan $searchStart [.code index end]]
	
	#
	# Add padding after the last annotation block to make the total heights match.
	#
	set lastAnnoLine [lineOfIndex [lindex [.code tag prevrange ANNO end] 1]]
	incr lastAnnoLine -1
	.code tag add ANNOLAST [format "%d.0" $lastAnnoLine] [format "%d.end" $lastAnnoLine]
	.anno tag configure ANNOLAST  -spacing3 [expr {$span * 15}]
}

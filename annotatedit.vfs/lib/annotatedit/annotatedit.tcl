#
# Requirements:
#	Tcl/Tk 8.5
#	ctext (enhanced text widget from TKLib)
#	text::sync (selectively sync text widgets)
# 
# ctext provides features like syntax coloring
# (not yet configured) and line numbers. I have disabled
# line numbers for now because they don't quite work
# with the variable line spacing I use to line things up.
# 
# I'm using text::sync instead of the built-in
# "peer" text widget mechanism because it provides
# finer control of what to sync. Specifically, I
# *don't* want to sync the styles applied to tags.
# Spans of code and comment text are tagged in
# both editors, but styled differently to hide them.
#

package require Tcl 8.5
package require Tk 8.5
package require ctext
package require text::sync

package provide annotatedit 0.1
namespace eval annotatedit {

#
# SetupEditor
# 
# This procedure creates the editor interface.
# The return value is a two-item list; the first
# item is the annotation editor widget and the second
# item is the code editor widget. Both are synced, so
# text edit operations may be applied to either widget.
# Tag styles, however, are not synced.
#
proc SetupEditor {} {

	set f [frame .f]
	
	# create text editor widgets - one for comments and one for code
	set font TkFixedFont
	variable linespacing [font metrics $font -linespace]
	set anno [ctext $f.anno \
			-xscrollcommand [list $f.anno_xscroll set] \
			-wrap none -height 20 -width 50 -linemap 0 -font $font \
			-tabstyle wordprocessor]
	set code [ctext $f.code \
			-xscrollcommand [list $f.code_xscroll set] \
			-yscrollcommand [list $f.yscroll set] \
			-wrap none -height 20 -width 50 -linemap 0 -font $font \
			-tabstyle wordprocessor]
	
	# each editor has its own horizontal scrollbar, but we only need one vertical
	scrollbar $f.anno_xscroll -command [list $f.anno xview] -orient horizontal
	scrollbar $f.code_xscroll -command [list $f.code xview] -orient horizontal
	scrollbar $f.yscroll -command [list $f.code yview] -orient vertical
	
	# put widgets in their frame and pack the frame in the window
	grid $f.anno $f.code $f.yscroll -sticky news
	grid $f.anno_xscroll $f.code_xscroll -sticky news
	grid rowconfigure $f 0 -weight 1
	grid columnconfigure $f 0 -weight 1
	grid columnconfigure $f 1 -weight 1
	pack $f -side top -fill both -expand true
	
	# synchronize the editor widgets (including vertical scrolling)
	text::sync::sync [list $anno $code] \
			-delete 1 -edit 1 -insert 1 -mark 1 -tag 1 -xview 0 -yview 1

	# configure each editor to elide (hide) text tagged as the other type
	$code tag configure ANNO -elide 1
	$anno tag configure CODE -elide 1
		
	return [list $anno $code]
}


#
# LoadCode
# 
# Parameters:
#	code, the code editor widget
#
proc LoadCode {code} {
 
	# display whatever gets stuffed in stdin
	set sample_text [read stdin]
	$code insert end $sample_text
	
}

#
# Little helpers to extract the line from a
# text index and to compute the span (height),
# in lines, between two indices.
#
proc lineOfIndex {textIndex} {
	return [lindex [split $textIndex .] 0]
}

proc blockSpan {startIndex endIndex} {
	return [expr {[lineOfIndex $endIndex] - [lineOfIndex $startIndex]}]
}

proc FormatText {anno code} {

	# used to locate search results and keep track of block sizes
	variable linespacing
	variable matchStart
	variable matchSpan
	variable searchStart 1.0
	variable tagSetNumber 0
	variable annoHeight 0
	variable codeHeight 0
	
	#
	# This loop searches the text (starting at index searchStart)
	# for the next instance of a comment block. For now, a comment
	# block is defined as one or more contiguous comment lines,
	# preceded and followed by blank comments. Comments that aren't
	# bordered in this way are ignored and displayed with the code.
	#
	while {{} != [set matchStart [$code search \
			-forward -count ::annotatedit::matchSpan -regexp -- \
			{^[[:blank:]]*#\n(?:[[:blank:]]*#.+?\n)+[[:blank:]]*#$} $searchStart end]]} {
		set codeHeight 0
		
		# tag anything between this comment block and the previous as code
		if {$searchStart ne $matchStart} {
			
			# marking this as code hides it from the comment editor
			# codeHeight keeps track of the height of this block
			$code tag add CODE $searchStart $matchStart
			set codeHeight [blockSpan $searchStart $matchStart]
			
			# highlight the first line of each code block
			# this shows where the associated annotation applies
			set tag [format "code-%d-top" $tagSetNumber]
			$code tag add $tag $searchStart [format "%d.end + 1 indices" [lineOfIndex $searchStart]]
			$code tag configure $tag -background "light blue" -spacing1 $linespacing
			
			#
			# The general process here is tagging alternating
			# blocks of comments and code. They come in pairs
			# (although one may be empty, in the case of "code"
			# between back-to-back comments, or the absent
			# "comment" before code on the first line of a file).
			# For every pair, I pad the height of the shorter
			# block to make it match the height of the taller.
			#
			# pad the bottom of this code block, if necessary, to match comment
			if {$annoHeight > $codeHeight} {
				set tag [format "code-%d-bottom" $tagSetNumber]
				$code tag add $tag [format "%d.0" [lineOfIndex [$code index "$matchStart - 1 indices"]]] $matchStart
				$code tag configure $tag -spacing3 [expr {($annoHeight - $codeHeight) * $linespacing}] -background "light blue"
			}
		}		
		
		# tag this comment block
		incr tagSetNumber
		incr matchSpan
		set matchEnd [$code index "$matchStart + $matchSpan indices"]
		$code tag add ANNO $matchStart $matchEnd
	
		# tag first line of block, with standard extra spacing
		set tag [format "anno-%d-top" $tagSetNumber]
		#$anno tag add $tag [format "%d.0" [lineOfIndex $matchStart]] [format "%d.end" [lineOfIndex $matchStart]]
		$anno tag add $tag [format "%d.0" [lineOfIndex $matchStart]] [format "%d.end + 1 indices" [lineOfIndex $matchStart]]
		$anno tag configure $tag -background "light blue"
		
		# pad the top of this comment, if necessary, to match code
		if {$codeHeight > $annoHeight} {
			$anno tag configure $tag -spacing1 [expr {$linespacing + (($codeHeight - $annoHeight) * $linespacing)}]
		} else {
			$anno tag configure $tag -spacing1 $linespacing
		}
	
		# annoHeight keeps track of this comment's height;
		# next time around, compare it to the associated code
		set annoHeight [blockSpan $matchStart $matchEnd]
		
		# look for the next comment block beginning where this one ends
		set searchStart $matchEnd
	}
	
	# tag anything after the last comment as a code block
	$code tag add CODE $searchStart end
	set codeHeight [blockSpan $searchStart [$code index end]]
	set tag [format "code-%d-top" $tagSetNumber]
	$code tag add $tag $searchStart [format "%d.end + 1 indices" [lineOfIndex $searchStart]]
	$code tag configure $tag -background "light blue" -spacing1 $linespacing
	
	#
	# Reminder: this bit doesn't play nice with an empty file.
	#
	
	# finish up with one more round of padding
	# this is actually important to facilitate syncro scrolling;
	# if the total height of displayed text doesn't match, the
	# editors won't line up in all cases, and users will be sad.
	if {$codeHeight > $annoHeight} {
		set lastAnnoLine [lineOfIndex [lindex [$code tag prevrange ANNO end] 1]]
		incr lastAnnoLine -1
		$code tag add ANNOLAST [format "%d.0" $lastAnnoLine] [format "%d.end" $lastAnnoLine]
		$anno tag configure ANNOLAST  -spacing3 [expr {($codeHeight - $annoHeight) * $linespacing}] -background "light blue"
	} elseif {$annoHeight > $codeHeight} {
		set tag [format "code-%d-bottom" $tagSetNumber]
		$code tag add $tag [$code index "end - 1 indices"]
		$code tag configure $tag -spacing3 [expr {($annoHeight - $codeHeight) * $linespacing}] -background "light blue"
	}

}

set widgets [SetupEditor]
set anno [lindex $widgets 0]
set code [lindex $widgets 1]
LoadCode $code
FormatText $anno $code

}

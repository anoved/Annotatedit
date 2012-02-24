#!/bin/sh

# \
  if (test -z "$WISH"); then export WISH=wish; fi
# \
  exec "$WISH" "$0" -name wish ${1+"$@"}

# ======================================================================

# example3.tcl --

# Text widget synchronization example.

# Version   : 0.0.1
# Author    : Mark G. Saye
# Email     : markgsaye@yahoo.com
# Copyright : Copyright (C) 2003
# Date      : April 11, 2003

# See the file "LICENSE.txt" or "LICENSE.html" for information on usage
# and distribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# ======================================================================

  namespace eval example {}

# ======================================================================

# init --

# Initialize this application.

proc example::init {} {

# ----------------------------------------------------------------------

  variable debug ; if { ![info exists debug] } { set debug 1 }

# ----------------------------------------------------------------------

  package require text::sync

  interp alias {} ns {} namespace current

# ----------------------------------------------------------------------

  return

}

# ======================================================================

# activate --

# Activate the proc listbox selection.
# Open a transient window with a text widget to edit the selected proc.

proc example::activate {W} {

# ----------------------------------------------------------------------

  debug 2 "proc activate \[$W\]\n"

# ----------------------------------------------------------------------

  set listbox $W.slist.listbox
  set text    $W.stext.text

  set active [$listbox index active]
  debug 3 "  active = \[$active\]\n"

  set proc [$listbox get $active]
  debug 3 "  proc = \[$proc\]\n"

  set index [$text search [list proc $proc] 1.0 end]
  debug 3 "  index = \[$index\]\n"

  $text see $index
  foreach {line char} [split $index .] { break }

# ----------------------------------------------------------------------

  if { [winfo exists $W.edit] } {
    set t $W.edit.scroll.text
  } else {
    toplevel $W.edit
    wm withdraw $W.edit
    update idletasks
    set t [scroll text $W.edit.scroll \
      -height 20 \
      -exportselection 0 \
      -width 60 \
      -wrap none \
    ]
    pack $W.edit.scroll -side top -expand 1 -fill both -padx 10 -pady 10
    text::sync::sync [list $text $t] \
      -xview 1 \
      -insert 1 \
      -delete 1 \
      -mark 1 \
      -tag 1
  }

  text::sync::configure $text -sync [list -offset [expr {$line - 1}]]

# ----------------------------------------------------------------------

  set args {}
  foreach arg [info args $proc] {
    if { [info default $proc $arg default] } {
      lappend args [list $arg $default]
    } else {
      lappend args $arg
    }
  }

  # We have two options:
  # 1. Disable sync of insert/delete subcommands,
  #    use the overloaded text widget command,
  #    re-enable insert/delete sync.
  # 2. Use real widget command (renamed into text::sync namespace)
  set choice 2
  if { $choice == 1 } {
    text::sync::configure $t -sync [list -delete 0 -insert 0]
    $t delete 1.0 end
    $t insert end "[list proc $proc $args [info body $proc]]"
    update idletasks
    text::sync::configure $t -sync [list -delete 1 -insert 1]
  } elseif { $choice == 2 } {
    text::sync::$t delete 1.0 end
    text::sync::$t insert end "[list proc $proc $args [info body $proc]]"
    text::sync::configure $t -sync [list -delete 1 -insert 1]
  }

  wm transient $W.edit $W
  wm deiconify $W.edit
  raise $W.edit

# ----------------------------------------------------------------------

  return

}

# ======================================================================

# close --

# Close an application window.

proc example::close {W} {

  debug 2 "proc close \[$W\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  ::destroy $W

  array unset _

  foreach w [winfo children .] {
    if { [string equal [winfo toplevel $w] $w] } { return }
  }

# ----------------------------------------------------------------------

  exit

}

# ======================================================================

# debug --

# Display debug messages.

proc example::debug {level string} {

  variable debug

  if { $level <= $debug } { puts -nonewline stderr "example: $string" }

  return

}

# ======================================================================

# create --

# Create the application GUI.

proc example::create {W} {

  debug 2 "proc create \[$W\]\n"

# ----------------------------------------------------------------------

  set slist $W.slist

  set listbox [scroll listbox $slist \
    -exportselection 0 \
    -height 20 \
    -width  30 \
  ]

  bind $listbox <Return>   [list event generate %W <<ListboxActivate>>]
  bind $listbox <Double-1> [list event generate %W <<ListboxActivate>>]
  bind $listbox <<ListboxActivate>> [list [ns]::activate $W]

# ----------------------------------------------------------------------

  set stext $W.stext

  set text [scroll text $stext \
    -height 20 \
    -exportselection 0 \
    -width 60 \
    -wrap none \
  ]

# ----------------------------------------------------------------------

  pack $slist -side left  -expand 0 -fill y    -padx 10 -pady 10
  pack $stext -side right -expand 1 -fill both -padx 10 -pady 10

# ----------------------------------------------------------------------

  foreach proc [lsort [info procs ::text::sync::*]] {
    $listbox insert end $proc
    set args {}
    foreach arg [info args $proc] {
      if { [info default $proc $arg default] } {
        lappend args [list $arg $default]
      } else {
        lappend args $arg
      }
    }
    $text insert end "[list proc $proc $args [info body $proc]]\n\n"
  }

# ----------------------------------------------------------------------

  return $W

}

# ======================================================================

# main --

proc example::main {{argc 0} {argv {}}} {

  debug 2 "proc main \[$argc\] \[$argv\]\n"

# ----------------------------------------------------------------------

  wm withdraw .

  set W [spawn]

# ----------------------------------------------------------------------

  return

}

# ======================================================================

# scroll --

# Create a scrolled widget with scrollbars.

proc example::scroll {type W args} {

  debug 2 "proc scroll \[$type\] \[$W\] \[$args\]\n"

# ----------------------------------------------------------------------

  set w $W.$type
  set x $W.x
  set y $W.y

# ----------------------------------------------------------------------

  array set arg [list \
    -borderwidth 0 \
    -highlightthickness 0 \
    -relief flat \
    -xscrollcommand [list $x set] \
    -yscrollcommand [list $y set] \
  ]
  array set arg $args

# ----------------------------------------------------------------------

  frame $W \
    -borderwidth 1 \
    -highlightthickness 1 \
    -relief sunken

  eval [linsert [array get arg] 0 $type $w]

  scrollbar $x -orient horizontal -command [list $w xview]
  scrollbar $y -orient vertical   -command [list $w yview]

  grid columnconfigure $W 1 -weight 1
  grid    rowconfigure $W 1 -weight 1

  grid $w -column 1 -row 1 -sticky nsew
  grid $x -column 1 -row 2 -sticky nsew
  grid $y -column 2 -row 1 -sticky nsew

# ----------------------------------------------------------------------

  return $w

}

# ======================================================================

# spawn --

# Spawn a new application window.

proc example::spawn {} {

  debug 2 "proc spawn\n"

# ----------------------------------------------------------------------

  regsub -all :: [ns] - name
  for {set i 1} {[winfo exists .$name-$i]} {incr i} {}
  set W .$name-$i

  toplevel $W

  wm protocol $W WM_DELETE_WINDOW [list [ns]::close $W]
  wm title $W "Text Sync Example"

  create $W

# ----------------------------------------------------------------------

  return $W

}

# ======================================================================

  if { [info exists argv0] && [string equal [info script] $argv0] } {
    uplevel #0 [list source $::tcl_rcFileName]
    example::init
    example::main $argc $argv
  } else {
    example::init
  }

# ======================================================================


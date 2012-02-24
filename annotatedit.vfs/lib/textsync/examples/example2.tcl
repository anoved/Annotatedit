#!/bin/sh

# \
  if (test -z "$WISH"); then export WISH=wish; fi
# \
  exec "$WISH" "$0" -name wish ${1+"$@"}

# ======================================================================

# example2.tcl --

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

# close --

# Close an application window.

proc example::close {W} {

  debug 2 "proc close \[$W\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  ::destroy $W

  unset _

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

# configure --

# Configure a widget's option.

proc example::configure {W option} {

  debug 2 "proc configure \[$W\] \[$option\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  set text $W.scroll-1.text

  array set sync [$text cget -sync]
  set old $sync($option)
  set new $_($option)

  debug 2 "  option \[$option\] = \[$old\] -> \[$new\]\n"

  $text configure -sync [list $option $new]

# ----------------------------------------------------------------------

  return

}

# ======================================================================

# create --

# Create the application GUI.

proc example::create {W} {

  debug 2 "proc create \[$W\]\n"

# ----------------------------------------------------------------------

  set colors [list black red darkgreen blue yellow orange]

  set texts {}
  for {set i 1} {$i <= 3} {incr i} {
    set scroll $W.scroll-$i
    set text [scroll text $scroll \
      -fg [lindex $colors $i] \
      -height 10 \
      -exportselection 0 \
      -width 60 \
      -wrap none \
    ]
    pack $scroll -side top -expand 1 -fill both -padx 10 -pady 10
    lappend texts $text

#   for {set line 0} {$line < 20} {incr line} {
#     $text insert end "This is line $line - make it long enough to test horizontal scrolling\n"
#   }

    bind $text <Enter> [list focus $text]

    foreach proc [lsort [info procs ::text::sync::*]] {
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
  }

  text::sync::sync $texts -xview 1

# $W.scroll-3.text configure -sync [list -offset 1]

# ----------------------------------------------------------------------

  set C $W.configure
  frame $C -relief flat -bd 1

  grid columnconfigure $C 0 -weight 1

  upvar #0 [ns]::$W _

  set row -1
  foreach {option value} [$W.scroll-1.text cget -sync] {
    if { [string equal $option -offset] } { continue }
    debug 3 "  set _($option) \[$value\]\n"
    set _($option) $value
    if { [string equal -with $option] } { continue }
    set opt [string range $option 1 end]
    set c $C.check-$opt
    checkbutton $c \
      -text "Synchronize $opt subcommands" \
      -variable [ns]::${W}($option) \
      -command [list [ns]::configure $W $option]
    label $C.label-$opt -text $opt
    entry $C.entry-$opt -textvariable [ns]::${W}($option)
#   pack $c -side top -expand 0 -fill none
    incr row
    grid $C.check-$opt -column 0 -row $row -sticky w
#   grid $C.label-$opt -column 1 -row $row -sticky w
#   grid $C.entry-$opt -column 2 -row $row -sticky ew
#   bind $C.entry-$opt <Return> [list [ns]::configure $W $option]
  }

  pack $C -side top -expand 0 -fill x -padx 10 -pady 10

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
    -borderwidth 1 \
    -highlightthickness 0 \
    -relief sunken \
    -xscrollcommand [list $x set] \
    -yscrollcommand [list $y set] \
  ]
  array set arg $args

# ----------------------------------------------------------------------

  frame $W \
    -borderwidth 0 \
    -highlightthickness 1 \
    -relief flat

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


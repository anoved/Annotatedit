# sync.tcl --

# Text widget synchronization package.

# Version   : 0.0.1
# Author    : Mark G. Saye
# Email     : markgsaye@yahoo.com
# Copyright : Copyright (C) 2003
# Date      : April 11, 2003

# See the file "LICENSE.txt" or "LICENSE.html" for information on usage
# and distribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# ======================================================================

  namespace eval text::sync {}

# ======================================================================

proc text::sync::pkginit_ {} {

# ----------------------------------------------------------------------

  interp alias {} ns {} namespace current

# ----------------------------------------------------------------------

  if { [catch {package require debug} version] } {
proc debug {level string} {
  variable debug
    if { $level <= $debug } { puts -nonewline stderr "sync: $string" }
  return
}
  }

  variable debug ; if { ![info exists debug] } { set debug 1 }

  debug 2 "proc pkginit_\n"

# ----------------------------------------------------------------------

  if { [catch {file normalize [info script]} scr] } {
    set scr [file join [pwd] [info script]]
  }
  set dir [file dirname $scr]

  debug 3 "  script = \[$scr\]\n"

# ----------------------------------------------------------------------

  variable pkginfo ; array set pkginfo [list \
    package      text::sync \
    version      0.0.1 \
    script       $scr \
    directory    $dir \
    name        "Text Sync" \
    description "A package to synchronize two or more text widgets." \
    copyright   "Copyright (C) 2003" \
    author      "Mark G. Saye" \
    email        markgsaye@yahoo.com \
    date        "April 11, 2003" \
  ]

# ----------------------------------------------------------------------

  variable options ; array set options [list \
    -sync {} \
  ]

  variable options_sync ; array set options_sync [list \
    -delete 0 \
    -edit   0 \
    -insert 0 \
    -mark   0 \
    -offset 0 \
    -scan   0 \
    -see    0 \
    -tag    0 \
    -window 0 \
    -with  {} \
    -xview  0 \
    -yview  0 \
  ]

  variable db ; array set db [list \
    -sync [list sync Sync] \
  ]

# ----------------------------------------------------------------------

  if { [string equal ::$pkginfo(package) [ns]] } {
    package provide $pkginfo(package) $pkginfo(version)
  }

# ----------------------------------------------------------------------

  return

}

# ======================================================================

proc text::sync::cget {W option} {

  debug 2 "proc cget \[$W\] \[$option\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  switch -- $option {
    -sync {
      set return {}
      foreach name [lsort [array names _ -*]] {
        lappend return $name [set _($name)]
      }
    }
    default {
      set return [$W cget $option]
    }
  }

# ----------------------------------------------------------------------

  debug 3 "  cget \[$option\] return \[$return\]\n"
  return $return

}

# ======================================================================

proc text::sync::cmd_ {W command args} {

  debug 2 "proc cmd_ \[$W\] \[$command\] \[$args\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  switch -- $command {
    cget -
    configure {
      debug 3 "  eval [linsert $args 0 $command $W]\n"
      set return [eval [linsert $args 0 $command $W]]
    }
    delete {
      if { $_(-delete) } {
        debug 3 "  eval [linsert $args 0 delete $W]\n"
        set return [eval [linsert $args 0 delete $W]]
      } else {
        set return [eval [linsert $args 0 $W delete]]
      }
    }
    insert {
      if { $_(-insert) } {
        debug 3 "  eval [linsert $args 0 insert $W]\n"
        set return [eval [linsert $args 0 insert $W]]
      } else {
        set return [eval [linsert $args 0 $W insert]]
      }
    }
    tag {
    	if {[info exists _(-tag)]} {
	        debug 3 "  _(-tag)='$_(-tag)'\n"
    		if {[set _(-tag)]} {
				# -with is a list of other text widgets to sync.    		
    			# This loop applies this command (tag) to each of those widgets.
    			# Check $args for subcommands to suppress for custom syncing.
    			if {![string equal "configure" [lindex $args 0]]} {
    				foreach text $_(-with) {
 		   				debug 3 "  eval [linsert $args 0 $text $command]\n"
    					eval [linsert $args 0 $text $command]
    				}
    			}
    		}
    	} else {
    	    debug 3 "  unused command \[$command\] \[$args\]\n"
    	}
    	set return [eval [linsert $args 0 $W $command]]
    }
    default {
      if { [info exists _(-$command)] } {
        debug 3 "  _(-$command)='$_(-$command)'\n"
        if { [set _(-$command)] } {
          foreach text $_(-with) {
#           uplevel _$t $command $args
            debug 3 "  eval [linsert $args 0 $text $command]\n"
            eval [linsert $args 0 $text $command]
          }
        }
      } else {
        debug 3 "  unused command \[$command\] \[$args\]\n"
      }
      debug 3 "  eval [linsert $args 0 $W $command]\n"
      set return [eval [linsert $args 0 $W $command]]
    }
  }

# ----------------------------------------------------------------------

  return $return

}

# ======================================================================

proc text::sync::configure {W args} {

  debug 2 "proc configure \[$W\] \[$args\]\n"

# ----------------------------------------------------------------------

  variable options
  variable options_sync

# ----------------------------------------------------------------------

  set error 0

  set argc [llength $args]
  debug 5 "  argc = \[$argc\]\n"

  switch -- $argc {
    0 {
      set return [$W configure]
#     foreach option [array names options] {
#       lappend return [configure:get_ $W $option]
#     }
      lappend return [configure:get_ $W -sync]
      set return [lsort -index 0 $return]
    }
    1 {
      set option [lindex $args 0]
      if { [info exists options($option)] } {
        set return [configure:get_ $W $option]
      } else {
        set return [$W configure $option]
      }
    }
    default {
      set return ""
      set _text {}
      foreach {option value} $args {
        debug 3 "  option = \[$option\] value = \[$value\]\n"
        if { [string equal -sync $option] } {
          foreach {opt val} $value {
            configure:set_ $W $opt $val
          }
        } else {
          lappend _text $option $value
        }
      }
      set error [catch [linsert $_text 0 $W configure] result]
    }
  }

# ----------------------------------------------------------------------

  if { $error } {
    set errorCode $::errorCode
    debug 3 "  error in proc configure\n"
    debug 3 "  error     = \[$error\]\n"
    debug 3 "  return    = \[$return\]\n"
    debug 3 "  errorCode = \[$errorCode\]\n"
    set code error
  } else {
    set code ok
  }

# ----------------------------------------------------------------------

  debug 7 "  configure return -code \[$code\] \[$return\]\n"
  return -code $code $return

}

# ======================================================================

# configure:get_ --

proc text::sync::configure:get_ {W option} {

  debug 4 "proc configure:get_ \[$W\] \[$option\]\n"

# ----------------------------------------------------------------------

  variable db
  variable options

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  set dbname  [lindex $db($option) 0]
  set dbclass [lindex $db($option) 1]
  set default $options($option)
  set value [cget $W $option]

  set return [list $option $dbname $dbclass $default $value]

# ----------------------------------------------------------------------

  debug 5 "  configure:get_ return \[$return\]\n"
  return $return

}
# ======================================================================

# configure:set_ --

proc text::sync::configure:set_ {W option value} {

  debug 4 "proc configure:set_ \[$W\] \[$option\] \[$value\]\n"

# ----------------------------------------------------------------------

  variable db
  variable options
  variable options_sync

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  # Overload global command
  set which [namespace which -command $W]
  debug 3 "  which = \[$which\]\n"
  if { ![string match [ns]* [namespace which -command $W]] } {
    debug 3 "  rename $W $W\n"
    rename $W $W
    interp alias {} ::$W {} [ns]::cmd_ $W
    array set _ [array get options_sync]
  }

  switch -- $option {
    -delete -
    -edit -
    -insert -
    -mark -
    -scan -
    -see -
    -tag -
    -window -
    -xview -
    -yview {
      set _($option) $value
      foreach text $_(-with) {
        set [ns]::${text}($option) $value
      }
    }
    -offset {
      debug 3 "  set _($option) \[$value\]\n"
      set _($option) $value
    }
    -with {
      foreach text $value {
        # Overload global command
        set which [namespace which -command $text]
        debug 3 "  which = \[$which\]\n"
        if { ![string match [ns]* $which] } {
          debug 3 "  rename $text $text\n"
          rename $text $text
          interp alias {} ::$text {} [ns]::cmd_ $text
          array set [ns]::${text} [array get _]
        }
      }
      set _($option) $value
    }
    default {
      return -code error "unknown option \"$option\""
    }
  }

# ----------------------------------------------------------------------

  debug 5 "  configure:set_ return\n"
  return

}

# ======================================================================

proc text::sync::delete {W args} {

  debug 2 "proc delete \[$W\] \[$args\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  set argc [llength $args]

  if { $argc == 0 } {
    set syntax "$W delete index1 ?index2 ...?"
    return -code error "wrong # args: should be $syntax"
  }

# ----------------------------------------------------------------------

  set zeros {}

  foreach index $args {

    set i [$W index $index]
    debug 3 "  index \[$index\] = \[$i\]\n"

    foreach {line char} [split $i .] { break }
    debug 3 "  index  line = \[$line\] char = \[$char\]\n"

    set zero [expr {$line - $_(-offset)}]
    debug 3 "  zero = \[$zero\]\n"

    lappend zeros $zero
  }

# ----------------------------------------------------------------------

  foreach text $_(-with) {
    set offset [set [ns]::${text}(-offset)]

    set argv {}
    foreach zero $zeros {
      set line [expr {$zero + $offset}]
      set indx ${line}.${char}
      debug 3 "  $text insert line = \[$line\] index = \[$indx\]\n"
      lappend argv $indx
    }
    eval [linsert $argv 0 $text delete]
  }

  eval [linsert $args 0 $W delete]

# ----------------------------------------------------------------------

  return

}

# ======================================================================

proc text::sync::insert {W index args} {

  debug 2 "proc insert \[$W\] \[$index\] \[$args\]\n"

# ----------------------------------------------------------------------

  upvar #0 [ns]::$W _

# ----------------------------------------------------------------------

  set argc [llength $args]

  if { $argc == 0 } {
    set wrong "$W insert index chars ?tagList chars tagList ...?"
    return -code error "wrong # args: should be $wrong"
  }

# ----------------------------------------------------------------------

  set i [$W index $index]
  debug 3 "  index \[$index\] = \[$i\]\n"

  foreach {line char} [split $i .] { break }
  debug 3 "  index  line = \[$line\] char = \[$char\]\n"

  set zero [expr {$line - $_(-offset)}]
  debug 3 "  zero = \[$zero\]\n"

  foreach text $_(-with) {
    set offset [set [ns]::${text}(-offset)]
    set line [expr {$zero + $offset}]
    set indx ${line}.${char}
    debug 3 "  $text insert line = \[$line\] index = \[$indx\]\n"
    eval [linsert $args 0 $text insert $indx]
  }

  eval [linsert $args 0 $W insert $i]

# ----------------------------------------------------------------------

  return

}

# ======================================================================

proc text::sync::sync {list args} {

  debug 2 "proc sync \[$list\] \[$args\]\n"

# ----------------------------------------------------------------------

  variable options_sync

# ----------------------------------------------------------------------

# set arg_list [list -delete -dump -index insert mark tag]

# array set arg [list \
#   -delete 1 \
#   -dump   1 \
#   -index  1 \
#   -insert 1 \
#   -mark   1 \
#   -tag    1 \
#   -with  {} \
#   -xview  0 \
#   -yview  0 \
# ]
# array set arg [array get options_sync]

# array set arg $args

# foreach {option value} $args {
#   if { [info exists arg($option)] } {
#     set arg($option) $value
#   } else {
#     debug 1 "  unrecognized argument \[$option\]\n"
#   }
# }

# ----------------------------------------------------------------------

  # Remove all instances of $W in -with list
# while { [set index [lindex $_(-with) $W]] > -1 } {
#   set _(-with) [lreplace $_(-with) $index $index]
# }
# set list $_(-with)
# lappend list $W
# set list [lsort -unique $list]

# ----------------------------------------------------------------------

  set i 0
  foreach W $list {
#   foreach name [array names arg] {
#     debug 3 "  set [ns]::${W}($name) \[$arg($name)\]\n"
#     set [ns]::${W}($name) $arg($name)
#   }

#   set [ns]::${W}(list) [lreplace $list $i $i]
    set with [lreplace $list $i $i]
#   debug 3 "  [ns]::${W}(list)= \[[set [ns]::${W}(list)]\]\n"
    set argv [linsert $args end -with $with]
    debug 3 "  argv = \[$argv\]\n"
    foreach {opt val} $argv {
      configure:set_ $W $opt $val
    }
    incr i
  }

# ----------------------------------------------------------------------

  return

}

# ======================================================================

  text::sync::pkginit_

  return

# ======================================================================


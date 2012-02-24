#!/bin/sh

# \
  if (test -z "$WISH"); then export WISH=wish; fi
# \
  exec "$WISH" "$0" -name wish ${1+"$@"}

# ======================================================================

# example1.tcl --

# Text widget synchronization example.

# Version   : 0.0.1
# Author    : Mark G. Saye
# Email     : markgsaye@yahoo.com
# Copyright : Copyright (C) 2003
# Date      : April 11, 2003

# See the file "LICENSE.txt" or "LICENSE.html" for information on usage
# and distribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# ======================================================================

  package require text::sync

  text .t1 -wrap word -height 0
  text .t2 -wrap word -height 0

  pack .t1 .t2 -expand 1 -fill both

  text::sync::sync [list .t1 .t2] \
    -insert 1 -delete 1 -mark 1 -scan 1 -tag 1

# ======================================================================


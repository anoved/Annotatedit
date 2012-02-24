package require starkit

if {[starkit::startup] eq "sourced" && [package vcompare [info patchlevel] 8.4.9] >= 0} {
	return
}

package require annotatedit

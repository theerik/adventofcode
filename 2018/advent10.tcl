#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math::geometry

# Get input from file
set fhandle [open "advent10.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 10: The Stars Align
# Track moving positions over time given starting position and velocity
foreach line [split $input "\n"] {
    scan $line "position=<%d,%d> velocity=<%d,%d>" xp yp xv yv
    lappend positions $xp $yp
    lappend velocities $xv $yv
}

# Part 1:
# Figure out when the message will display and display the expected positions
# at that time in a grid so the user can read them.
# As a proxy for time of readable alignment, calculate the area of the
# bounding box of the positions at each step and find the minimum.
set lastarea 20000000000
for {set step 0} {1} {incr step} {
    lmap {xp yp} $positions {xv yv} $velocities {lappend outposL [expr {$xp + $xv}] [expr {$yp + $yv}]}
    lassign [::math::geometry::bbox $outposL] xmin ymin xmax ymax
    set area [expr {($xmax - $xmin) * ($ymax - $ymin)}]
    if {$area > $lastarea} {
        break
    }
    set positions $outposL
    set outposL {}
    set lastarea $area
}
# Found it.  Transfer the list to an easier-to-check form
foreach {x y} $positions {
    set posA($x,$y) "*"
}
for {set y $ymin} {$y <= $ymax} {incr y} {
    for {set x $xmin} {$x <= $xmax} {incr x} {
        if [info exists posA($x,$y)] {
            append outS "*"
        } else {
            append outS "."
        }
    }
    puts "$outS"
    set outS ""
}

# Part 2:
# ...Aaaannd how long would that take?
puts "Total seconds: $step"
#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math
package require math::geometry

# Get input from file
set fhandle [open "advent6.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 6: Chronal Coordinates
# Given: a list of positive integer "X, Y" coordinates.

# get rid of spaces, form a list of coordinates alternating X & Y, and
# compute the min & max X & Y coords
set inL [split [string map {" " ""} $input] "\n,"]
set numCoords [expr {[llength $inL] / 2}]
lassign [::math::geometry::bbox $inL] xmin ymin xmax ymax


# Part 1:
# For every point on a grid, determine the closest given coord to that point,
# using Manhattan distance measurements.
# Each coord will sweep out some area, in number of points to which it is closest.
# An area is defined as infinite if it touches the bounding box, as no nearer
# coords can possibly exist.
# Determine the largest area that isn't infinite.

# For every point on a grid, determine the closest given coord to that point,
# using Manhattan distance measurements.  Tally that point to the coord.  If
# we're on a bounding box edge, add this coord to the list of inifinite areas.
set marker $numCoords
incr marker
for {set x $xmin} {$x <= $xmax} {incr x} {
    for {set y $ymin} {$y <= $ymax} {incr y} {
        set distL [lmap {cx cy} $inL {expr {abs($x - $cx) + abs($y - $cy)}}]
        set idx [lsearch -all $distL [::math::min {*}$distL]]
        if {[llength $idx] == 1} {
            lappend areaCoords($idx) [list $x $y]
            if {($x == $xmin) || ($x == $xmax) || ($y == $ymin) || ($y == $ymax)} {
                set infinite($idx) true
            }
        }
    }
}
set areaL [lrepeat $numCoords 0]
foreach name [array names areaCoords] {
    lset areaL $name [llength $areaCoords($name)]
}
foreach name [array names infinite] {
    lset areaL $name 0
}
set largest [::math::max {*}$areaL]
puts "The largest non-infinite area is $largest"

# Part 2:
# For each point in the space, determine if the sum of Manhattan distances to
# all coords is < 1000.  This should be a contiguous region.  Find its size.
for {set x $xmin} {$x <= $xmax} {incr x} {
    for {set y $ymin} {$y <= $ymax} {incr y} {
        set distL [lmap {cx cy} $inL {expr {abs($x - $cx) + abs($y - $cy)}}]
        set totDist [tcl::mathop::+ {*}$distL]
        if {$totDist < 10000} {
            lappend regionPoints [list $x $y]
        }
    }
}
puts "The size of second region is [llength $regionPoints]"



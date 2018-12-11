#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math
package require struct::matrix
namespace import ::tcl::mathop::*

# Day 11: Chronal Charge
#
# Given a seed, compute a complex iterative function over a 300x300 array.
# After doing it wrong, I got a pointer to a new algorithmic concept called
# "summed-area table" (https://en.wikipedia.org/wiki/Summed-area_table).
# To start, use the input seed and the wierd algo to build the table.
set input 1309
for {set x 0} {$x <= 300} {incr x} {set sapA($x,0) 0}
for {set y 1} {$y <= 300} {incr y} {
    set sapA(0,$y) 0
    for {set x 1} {$x <= 300} {incr x} {
        set power [expr {(($x + 10) * $y) + $input}]
        set power [expr {($power * ($x + 10))}]
        set power [expr {int(($power % 1000) / 100) - 5}]
        lappend rowL $power
        set sapA($x,$y) [expr {$power + $sapA([- $x 1],$y)
                                + $sapA($x,[- $y 1])
                                - $sapA([- $x 1],[- $y 1]) }]
    }
}
puts "Summed-area table built."

# Part 1:
# Find the UL corner of the 3x3 subgrid with the highest total power
#
# Part 2:
# Find the UL corner of the subgrid of ANY size with the highest total power.
#
# Scan the table, looking at every possible size for every pixel.  Track the
# maximum total of subgrids of size==3, and of all size subgrids.
set max3Tot 0
set maxTot 0
for {set y 1} {$y <= 300} {incr y} {
    for {set x 1} {$x <= 300} {incr x} {
        set maxsize [expr {300 - ($x < $y ? $y : $x)}]
        set stL {0}
        for {set size 1} {$size < $maxsize} {incr size} {
            set subtot [expr {  $::sapA($x,$y)
                              + $::sapA([+ $x $size],[+ $y $size])
                              - $::sapA([+ $x $size],$y)
                              - $::sapA($x,[+ $y $size]) }]
            if {($size == 3) && ($max3Tot < $subtot)} {
                set max3Tot $subtot
                set max3X [+ $x 1]
                set max3Y [+ $y 1]
            }
            lappend stL $subtot
        }
        if {$maxTot < [::math::max {*}$stL]} {
            set maxTot [::math::max {*}$stL]
            set maxX [+ $x 1]
            set maxY [+ $y 1]
            set maxSize [lsearch $stL $maxTot]]
        }
    }
    puts -nonewline "." ; flush stdout
}

puts "\nThe corner of the highest 3x3 subtotal ($max3Tot) is $max3X,$max3Y"
puts "The corner of the highest any size subtotal ($maxTot) is $maxX,$maxY,$maxSize"

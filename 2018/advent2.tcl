#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Get input from file
set fhandle [open "advent2.txt"]
set input [read -nonewline $fhandle]
close $fhandle
set inL [split $input "\n"]

# Inventory tracking - Part 1:
# For each ID in the input list, count the number of letters appearing
# exactly twice and exactly thrice.  If a particular ID has one or more
# doubles, increment the double count.  If it has one or more triples,
# increment the triple count.  The  desired "checksum" answer is the
# product of the two: doubles * triples.
foreach id $inL {
    foreach letter [split $id ""] {
        incr letterCounts($letter)
    }
    if {2 in [array get letterCounts]} {
        incr doubles
    }
    if {3 in [array get letterCounts]} {
        incr triples
    }
    array unset letterCounts
}
puts "Checksum is: [expr $doubles * $triples]"

# Inventory tracking - Part 2:
# Search the list to find two IDs that differ by only one changed character.
# Return the common letters.
for {set idx 1} {$idx < [llength $inL]} {incr idx} {
    set base [lindex $inL $idx-1]
    foreach tgt [lrange $inL $idx end] {
        set matches [lmap b [split $base ""] t [split $tgt ""] {expr {$b != $t}}]
        if {[tcl::mathop::+ {*}$matches] == 1} {
            incr idx [llength $inL]
            break
        }
    }
}
set loc [lsearch $matches 1]
puts "The IDs are: \n$base & \n$tgt \nThe common letters are: \
        \n[string replace $base $loc $loc]"


#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
set fhandle [open "advent25.txt"]
#set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Util
proc lremove {lname elemval} {
    upvar $lname lst
    set idx [lsearch $lst $elemval]
    if {$idx == -1} {return false}
    set lst [lreplace $lst $idx $idx]
    return true
}


# Day 25: Four-Dimensional Adventure
#
# Input is a list of 4D coordinates.  These group into constellations if
# the manhattan distance from one point to another in the same constellation
# is 3 or less.
foreach line [split $input "\n"] {
    lappend pointL [split $line ","]
}

# Group into constellations.
proc manDist4D {p1 p2} {
    lassign $p1 p1x p1y p1z p1w
    lassign $p2 p2x p2y p2z p2w
    return [expr {abs($p1x - $p2x) + abs($p1y - $p2y) + abs($p1z - $p2z) + abs($p1w - $p2w)}]
}
proc pointInConst {point const} {
    foreach cp $const {
#puts -nonewline "$cp -> $point: " ; flush stdout
        if {[manDist4D $point $cp] <= 3} {
#puts [manDist4D $point $cp]
            return true
        }
#puts [manDist4D $point $cp]
    }
    return false
}

# Assign points to constellations
array set constA {}
foreach point $pointL {
    foreach const [array names constA] {
        if {[pointInConst $point $constA($const)]} {
            lappend constA($const) $point
            set point {}
            break
        }
    }
    if {$point ne {}} {
        lappend constA(const[incr maxid]) $point
    }
}
# Merge constellations if needed
set remL [array names constA]
foreach const $remL {
    lremove remL $const
    set breakout false
#puts "const: $const \tremL: $remL"
    foreach c2 $remL {
        foreach point $constA($const) {
#puts "point $point; c2: $c2"
            if {[pointInConst $point $constA($c2)]} {
puts "merge! $const with $c2"
                # combine const into c2
                lappend constA($c2) {*}$constA($const)
                unset constA($const)
                set breakout true
                break
            }
        }
        if $breakout break
    }
}

parray constA
puts "There were [llength [array names constA]] constellations."


#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
#set fhandle [open "advent15.txt"]
set fhandle [open "temp15.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 15: Beverage Bandits
#
# Another automata system, a la Nethack this time.  Read in a map showing:
# walls (#), open floor (.), goblins (G), and elves (E).
set row 0
set col 0
set maxcol 0
set id 100
foreach line [split $input "\n"] {
    set col 0
    foreach char [split $line {}] {
        switch -exact -- $char {
            "#" -
            "." {
                set map($col,$row) $char
            }
            "G" {
                set map($col,$row) $char
                set critters([incr id],hp) 200
                set critters($id,loc) [list $row $col $id]
                set critters($id,type) goblin
                lappend goblinL $critters($id,loc)
            }
            "E" {
                set map($col,$row) $char
                set critters([incr id],hp) 200
                set critters($id,loc) [list $row $col $id]
                set critters($id,type) elf
                lappend elfL $critters($id,loc)
            }
        }
        incr col
    }
    incr row
    if {$col > $maxcol} {
        set maxcol $col
    }
}

proc getNextCritter {lname} {
    global toMoveL
    set out [lindex $toMoveL end]
    set toMoveL [lreplace $toMoveL end end]
    return $out
}

proc makeAttack {charL} {

}

proc moveCritter {charL} {

    return newCharL
}

proc findDist {fromL toL} {
    return [expr {abs([lindex $fromL 0] - [lindex $toL 0]) \
                + abs([lindex $fromL 1] - [lindex $toL 1])}]
}

proc combatRound {} {
    global toMoveL movedL elfL goblinL
    set toMoveL [lsort -decreasing [concat $elfL $goblinL]]
    set movedL {}
    while {[llength $toMoveL] > 0} {
        set active [getNextCritter toMoveL]
        if {[canAttack $active]} {
            makeAttack $active
            lappend movedL $active
        } else {
            lappend movedL [moveCritter $active]
        }
    }
}

# Printmap creates diag printouts of the current map.
proc printmap {} {
    global elfL goblinL critters
    for {set y 0} {$y < $::row} {incr y} {
        for {set x 0} {$x < $::maxcol} {incr x} {
            puts -nonewline $::map($x,$y)
        }
        puts ""
    }
    puts "Elfs: $elfL \nGobs: $goblinL"
    parray critters
}
puts "Rows: $row  Cols: $maxcol"
printmap


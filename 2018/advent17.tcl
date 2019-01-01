#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
set fhandle [open "advent17.txt"]
#set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle


# Day 17: Reservoir Research
#
# Input: a set of line segments that are "clay" - all others are sand.  Segs
# come in format "x=487, y=571..598", where either axis can be the single point.
# There will be a single water source at 500,0.
lassign {0 0 1000 1000} xmax ymax xmin ymin
foreach line [split $input "\n"] {
    if {[scan $line "x=%d, y=%d..%d" x0 y1 y2] == 0} {
        scan $line "y=%d, x=%d..%d" y0 x1 x2
        for {set x $x1} {$x <= $x2} {incr x} {
            set soilMap($x,$y0) "#"
        }
        if {$x2 > $xmax} {set xmax $x2}
        if {$y0 > $ymax} {set ymax $y0}
        if {$x1 < $xmin} {set xmin $x1}
        if {$y0 < $ymin} {set ymin $y0}
    } else {
        for {set y $y1} {$y <= $y2} {incr y} {
            set soilMap($x0,$y) "#"
        }
        if {$x0 > $xmax} {set xmax $x0}
        if {$y2 > $ymax} {set ymax $y2}
        if {$x0 < $xmin} {set xmin $x0}
        if {$y1 < $ymin} {set ymin $y1}
    }
}
# Fill the remaining with sand
for {set y 1} {$y <= $ymax + 2} {incr y} {
    for {set x [expr {$xmin - 2}]} {$x <= ($xmax + 2)} {incr x} {
        if {![info exists soilMap($x,$y)]} {
            set soilMap($x,$y) "."
        }
    }
}
proc printmap {{fn stdout}} {
    if {$fn ne "stdout"} {
        set fh [open $fn w]
    } else {
        set fh stdout
    }
    for {set y 1} {$y <= $::ymax + 1} {incr y} {
        puts -nonewline $fh [format "%4d " $y]
        for {set x [expr {$::xmin - 2}]} {$x <= $::xmax + 1} {incr x} {
            puts -nonewline $fh $::soilMap($x,$y)
        }
        puts $fh ""
    }
    if {$fn ne "stdout"} {
        close $fh
    }
}
puts "X: $xmin-$xmax  Y: $ymin-$ymax"
#printmap
puts ""

# Part 1:
# Water is turned on at 500,0.  It drops 1 point/turn through sand, but cannot
# penetrate clay.  If water covers clay and is held in on the sides, it will
# form a pool.  Counting water in pools and water moving in sand once
# steady state is reached, how many tiles can water reach?

proc lenqueue {lname elem} {
    upvar $lname lst
    if {$elem ni $lst} {
        lappend lst $elem
    }
}
proc lpop {lname} {
    upvar $lname lst
    set out [lindex $lst 0]
    set lst [lrange $lst 1 end]
    return $out
}

# Helper proc - when we hit a floor, deal with lateral motion.
proc findWalls {wx wy} {
    global soilMap
    set wxl $wx
    while {$soilMap($wxl,$wy) eq "|"} {incr wxl -1}
    set wxr $wx
    while {$soilMap($wxr,$wy) eq "|"} {incr wxr}
    # If they're both walls, flood the space between and search from the
    # point on the level above where the water came in.  Returns the rightmost
    # point if there are more than one.
    if {$soilMap($wxl,$wy) eq "#" && $soilMap($wxr,$wy) eq "#"} {
        set wy1 [expr {$wy - 1}]
        set inx {}
        for {set x [incr wxl]} {$x < $wxr} {incr x} {
            set soilMap($x,$wy) "~"
            if {$soilMap($x,$wy1) eq "|"} { lappend inx $x }
        }
        set outL [lmap ix $inx {list $ix $wy1}]
#        foreach ix $inx {lappend outL [list $ix $wy1]}
        return $outL
    }
    # Check to see if there's spillover on either side, then advance if not.
    set wy1 [expr {$wy + 1}]
    set outL {}
    if {$soilMap([expr {$wxl + 1}],$wy1) in {"." "|"}} {
       lappend outL [list [expr {$wxl + 1}] $wy1]
    } else {
       lappend outL [list $wxl $wy]
    }
    if {$soilMap([expr {$wxr - 1}],$wy1) in {"." "|"}} {
       lappend outL [list [expr {$wxr - 1}] $wy1]
    } else {
       lappend outL [list $wxr $wy]
    }
    return $outL
}

lappend waterQ {500 1}
while {![llength $waterQ] == 0} {
    lassign [lpop waterQ] waterx watery
    # Don't follow anything off the bottom
    if {$watery > $ymax} {
        continue
    }
    # Process the current point
    switch -- $soilMap($waterx,$watery) {
        "." { set soilMap($waterx,$watery) "|" }
        "|" { }
        "#" { continue }
        "~" { continue }
    }
    # Perform spill-seeking process
    # First, water moves down until stopped.
    if {$soilMap($waterx,[expr {$watery + 1}]) ni {"#" "~"}} {
        lenqueue waterQ [list $waterx [incr watery]]
        continue
    }
    # Go sideways to find the walls.  Returns next point on each side.
    foreach w [findWalls $waterx $watery] {
        lenqueue waterQ $w
    }
}
puts ""
#printmap
printmap out.txt

proc countWater {} {
    for {set y $::ymin} {$y <= $::ymax} {incr y} {
        for {set x [expr {$::xmin - 2}]} {$x <= ($::xmax + 2)} {incr x} {
            if {$::soilMap($x,$y) in {"|" "~"}} {
                incr waterCount
            }
            if {$::soilMap($x,$y) eq "~"} {
                incr poolCount
            }
        }
    }
    return "$waterCount total and $poolCount pooled"
}

puts "There are [countWater] water-accessible tiles."

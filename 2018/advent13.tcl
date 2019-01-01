#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}


# Read the input file
set fhandle [open "advent13.txt"]
#set fhandle [open "temp3.txt"]
set input [read -nonewline $fhandle]
close $fhandle
set inL [split $input "\n"]

# Day 13: Mine Cart Madness
#
# Input is a map of tracks, built with | & - as straights, \ & / as curves, and
# and + as intersections; with starting positions & directions of carts marked
# by < > ^ & v.  (Cart starting positions are always straight lines.)

# Build the map.  Map is an array of (x,y); carts are 4-element lists:
# {xPosition, yPosition, currentDirection, nextTurn}
set row 0
set maxcol 0
set carts {}
foreach line $inL {
    set col 0
    foreach char [split $line ""] {
        switch -glob -- $char {
            {[><]} {
                set map($col,$row) "-"
                lappend carts [list $row $col $char 0]
            }
            {[v^]} {
                set map($col,$row) "|"
                lappend carts [list $row $col $char 0]
            }
            {[|/\\+-]} {
                set map($col,$row) $char
            }
        }
        incr col
    }
    incr row
    if {$col > $maxcol} {
        set maxcol $col
    }
}
# Normalize by filling unused spots with dots.
for {set y 0} {$y <= $::row} {incr y} {
    for {set x 0} {$x <= $::maxcol} {incr x} {
        if {![info exists ::map($x,$y)]} {
            set ::map($x,$y) "."
        }
    }
}

# Helper procs.
# MoveCart will take a cart, check the map, and move it.  It returns the new
# cart vector, with X if it exploded.  It's effectively a state machine with
# a state vector of $cart, and a transition table of $::map.
proc moveCart {cartL} {
    lassign $cartL row col dir turn
    switch -- $::map($col,$row) {
        "-" {
            switch -- $dir {
                ">" { set newCart [list $row [expr $col + 1] $dir $turn]}
                "<" { set newCart [list $row [expr $col - 1] $dir $turn]}
                "^" { error "Cart at $col,$row going $dir ran into $::map($col,$row) "}
                "v" { error "Cart at $col,$row going $dir ran into $::map($col,$row) "}
                default { error "Cart at $col,$row ($::map($col,$row)) got unknown dir $dir "}
            }
        }
        "|" {
            switch -- $dir {
                ">" { error "Cart at $col,$row going $dir ran into $::map($col,$row) "}
                "<" { error "Cart at $col,$row going $dir ran into $::map($col,$row) "}
                "^" { set newCart [list [expr $row - 1] $col $dir $turn]}
                "v" { set newCart [list [expr $row + 1] $col $dir $turn]}
                default { error "Cart at $col,$row ($::map($col,$row)) got unknown dir $dir "}
            }
        }
        "/" {
            switch -- $dir {
                ">" { set newCart [list [expr $row - 1] $col "^" $turn]}
                "<" { set newCart [list [expr $row + 1] $col "v" $turn]}
                "^" { set newCart [list $row [expr $col + 1] ">" $turn]}
                "v" { set newCart [list $row [expr $col - 1] "<" $turn]}
                default { error "Cart at $col,$row ($::map($col,$row)) got unknown dir $dir "}
            }
        }
        "\\" {
            switch -- $dir {
                ">" { set newCart [list [expr $row + 1] $col "v" $turn]}
                "<" { set newCart [list [expr $row - 1] $col "^" $turn]}
                "^" { set newCart [list $row [expr $col - 1] "<" $turn]}
                "v" { set newCart [list $row [expr $col + 1] ">" $turn]}
                default { error "Cart at $col,$row ($::map($col,$row)) got unknown dir $dir "}
            }
        }
        "+" {
            switch -- $dir {
                ">" {
                    set newTurn [expr {($turn + 1) % 3}]
                    switch -- $turn {
                        0   {set newCart [list [expr $row - 1] $col "^" $newTurn]}
                        1   {set newCart [list $row [expr $col + 1] $dir $newTurn]}
                        2   {set newCart [list [expr $row + 1] $col "v" $newTurn]}
                    }
                }
                "<" {
                    set newTurn [expr {($turn + 1) % 3}]
                    switch -- $turn {
                        0   {set newCart [list [expr $row + 1] $col "v" $newTurn]}
                        1   {set newCart [list $row [expr $col - 1] $dir $newTurn]}
                        2   {set newCart [list [expr $row - 1] $col "^" $newTurn]}
                    }
                }
                "^" {
                    set newTurn [expr {($turn + 1) % 3}]
                    switch -- $turn {
                        0   {set newCart [list $row [expr $col - 1] "<" $newTurn]}
                        1   {set newCart [list [expr $row - 1] $col $dir $newTurn]}
                        2   {set newCart [list $row [expr $col + 1] ">" $newTurn]}
                    }
                }
                "v" {
                    set newTurn [expr {($turn + 1) % 3}]
                    switch -- $turn {
                        0   {set newCart [list $row [expr $col + 1] ">" $newTurn]}
                        1   {set newCart [list [expr $row + 1] $col $dir $newTurn]}
                        2   {set newCart [list $row [expr $col - 1] "<" $newTurn]}
                    }
                }
                default { error "Cart at $col,$row ($::map($col,$row)) got unknown dir $dir "}
            }
        }
        default { error "Map at $col,$row was unknown: $::map($col,$row)"}
    }
    return $newCart
}

# Printmap creates diag printouts of the current map.
proc printmap {} {
    for {set y 0} {$y <= $::row} {incr y} {
        for {set x 0} {$x <= $::maxcol} {incr x} {
            puts -nonewline $::map($x,$y)
        }
        puts ""
    }
    puts "Carts are $::carts"
}

# Detect collision looks for a location match between a moved cart and the
# list of others.
proc detectCollision {newcart cartL} {
    lassign $newcart row col dir turn
    foreach cart $cartL  {
        if {([lindex $cart 0] == $row) && ([lindex $cart 1] == $col)} {
            puts ""
            puts " BOOM!!!! at ($col,$row)"
            puts ""
            return $cart
        }
    }
    return ""
}

# MoveAllCarts will sort the input list and iterate along it, transferring
# carts from the list of remaining carts to the list of moved carts.  After
# each cart is moved, we look for collisions.  When a collision is detected,
# we remove both carts from the lists.
proc moveAllCarts {cartL} {
    set remainL [lsort -index 0 -integer [lsort -index 1 -integer $cartL]]
    set movedL {}
    while {[llength $remainL] > 0} {
        set cart [moveCart [lindex $remainL 0]]
        set remainL [lreplace $remainL 0 0]

        if {[set match [detectCollision $cart [concat $movedL $remainL]]] ne ""} {
            puts "Collision detected: $cart matches $match. Tick $::tick. cart list: $movedL -- $remainL"
            if {[set idx [lsearch $movedL $match]] != -1} {
                set movedL [lreplace $movedL $idx $idx]
            } elseif {[set idx [lsearch $remainL $match]] != -1} {
                set remainL [lreplace $remainL $idx $idx]
            } else {
                error "match $match detected, but not found in: $movedL -- $remainL"
            }
        } else {
            lappend movedL $cart
        }
    }
    incr ::tick
    return $movedL
}

# Document start conditions:
printmap

# Part 1:
# what is the coordinates of the first collision?
set cartNum [llength $carts]
set tick 0
while {$cartNum == [llength $carts]} {
    set carts [moveAllCarts $carts]
#    printmap
}

# Part 2:
# when all but one cart has been removed after collision,
# where is the last cart?
while {[llength $carts] > 1} {
    set carts [moveAllCarts $carts]
}
lassign [lindex $carts 0] row col dir turn
puts "Last cart is at ($col,$row)"

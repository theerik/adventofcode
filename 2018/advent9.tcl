#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math

# Read the input file
#set fhandle [open "temp.txt"]
set fhandle [open "advent9.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 9: Marble Mania
# Perform a series of operations on a circularly linked list.
# Base operation:  Insert incrementing number into position 2 (CW) of the list.
#                  Rotate the list so the inserted number is head.
#                  Current player gets no score.
# Special (if number % 23 is 0): current player scores the number.
#          Item end-7 is removed and current player scores that number also.
#          Rotate the list so that the new end-7 is the head.
scan $input "%d players; last marble is worth %d points" numPlayers endCnt

# Tcl lists don't work for this, so we need to use arrays as pointers.
# Procs for each op update the global circle, and return the point score for
# the current player.
set circle(0,next) 0
set circle(0,prev) 0
set current 0

proc baseOp {number} {
    global circle current
    set circle($number,next) $circle($circle($current,next),next)
    set circle($number,prev) $circle($current,next)
    set circle($circle($number,prev),next) $number
    set circle($circle($number,next),prev) $number
    set current $number
    return 0
}
proc op23 {number} {
    global circle current
    for {set i 0; set prev $current} {$i < 7} {incr i} {
        set prev $circle($prev,prev)
    }
    set score [expr {$number + $prev}]
    set circle($circle($prev,prev),next) $circle($prev,next)
    set circle($circle($prev,next),prev) $circle($prev,prev)
    set current $circle($prev,next)
    return $score
}

# Part 1:
# For the given number of players and rounds, what is the high score?
for {set round 1} {$round <= $endCnt} {incr round} {
    set player [expr {$round % $numPlayers}]
    incr score($player) [expr {($round % 23) == 0 ? [op23 $round] : [baseOp $round]}]
}

set max [::math::max {*}[lmap k [array names score] {list $score($k)}]]
puts "$numPlayers players for $endCnt rounds: The high score is $max"

# Part 2:
# What if the number of rounds was 100x larger?
for {} {$round <= ($endCnt * 100)} {incr round} {
    set player [expr {$round % $numPlayers}]
    incr score($player) [expr {($round % 23) == 0 ? [op23 $round] : [baseOp $round]}]
}

set max [::math::max {*}[lmap k [array names score] {list $score($k)}]]
puts "$numPlayers players for [expr $endCnt * 100] rounds: The high score is $max"
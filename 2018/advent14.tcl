#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

set input 909441

# Day 14: Chocolate Charts
#
# Build a "recipe score" scoreboard list.  Initial values are 3 & 7.
# Choose two indices, starting with 0 & 1.
# For each round:
# - Add the list values at the indices;
# - append the digits separately as new scores on the scoreboard;
# - increment the indices by an amount equal to the value they currently
#   point to + 1 (modulo current list length, of course).
set scoreL {3 7}
set indices {0 1}

proc addRound {idx1 idx2} {
    set v1 [lindex $::scoreL $idx1]
    set v2 [lindex $::scoreL $idx2]
    lappend ::scoreL {*}[split [expr $v1 + $v2] {}]
    set len [llength $::scoreL]
    return [list [expr {($idx1 + $v1 + 1) % $len}] [expr {($idx2 + $v2 + 1) % $len}]]
}

# Part 2:
#
# Use the input as a target to match in the score string.  Display the index of the left edge
# of the substring in the score string.
while {[string first $input [join [lrange $scoreL end-20 end] {}]] == -1} {
    set indices [addRound {*}$indices]
}
puts "There are [string first $input [join $scoreL {}]] recipes before the target."

# Part 1:
# What is the 10-digit number made of the sum of the next 10 scores after
# the first $input scores?
while {[llength $scoreL] < $input+10} {
    set indices [addRound {*}$indices]
}
puts "The 10 scores after the first $input are: [join [lrange $scoreL $input $input+9] {}]"

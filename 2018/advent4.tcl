#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math

# Read the input file
set fhandle [open "advent4.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 4: Repose Record
# From the input, determine which guard is most likely to be asleep at
# which minute.  Input format is:
# [<timestamp>] Guard #<guardNum> begins shift
# [<timestamp>] falls asleep
# [<timestamp>] wakes up
# where <timestamp> is in the format YYYY-MM-DD hh:mm.

# I note that I verified the input to ensure that times did indeed sort
# correctly, and that no guard was still sleeping at the end of his shift.
# Therefore, I've removed the code that checked for these conditions as it
# confused the flow for no gain.

# Input data is arbitrarily ordered; needs to be organized to be useful.
set inL [lsort [split $input "\n"]]

# Read input, extract data
set dateFmt "%Y-%m-%d %H:%M"
foreach line $inL {
    # Get the parameters
    # timestamps are in seconds, so remember to / 60 for mins
    switch -regexp -matchvar matchL -- $line {
        {\[(.+)] Guard #([0-9]+) begins shift} {
            set gdNum [lindex $matchL 2]
            if {![info exists napLog(map,$gdNum)]} {
                # new guards get new maps
                set napLog(map,$gdNum) [lrepeat 60 0]
            }
        }
        {\[(.+)] falls asleep} {
            set sleepmin [scan [clock format [clock scan [lindex $matchL 1] \
                                    -format $dateFmt] -format "%M"] "%d"]
        }
        {\[(.+)] wakes up} {
            set wakemin [scan [clock format [clock scan [lindex $matchL 1] \
                                    -format $dateFmt] -format "%M"] "%d"]
            incr napLog(total,$gdNum) [expr {$wakemin - $sleepmin}]
            for {set idx $sleepmin} {$idx < $wakemin} {incr idx} {
                set napLog(map,$gdNum) [lreplace $napLog(map,$gdNum) \
                        $idx $idx [expr {[lindex $napLog(map,$gdNum) $idx] + 1}]]
            }
        }
        default {
            puts "unparsable line $line"
            exit
        }
    }
}

# Part 1:
# Identify the guard that slept the most minutes; map his minutes and
# find which one he was most asleep.
set maxsleep 0
set maxguard 0

# Part 2:
# Which guard is most asleep at a given minute most often?
set maxminute 0
set maxminguard 0

foreach guard [array names napLog total,*] {
    set gdNum [string range $guard 6 end]
    # Part 1: Find the guard with the highest total time
    if {$napLog(total,$gdNum) > $maxsleep} {
        set maxsleep $napLog(total,$gdNum)
        set maxguard $gdNum
    }
    # Part 2: Find the guard with the highest individual minute total
    set napLog(max,$gdNum) [::math::max {*}$napLog(map,$gdNum)]
    if {$napLog(max,$gdNum) > $maxminute} {
        set maxminute $napLog(max,$gdNum)
        set maxminguard $gdNum
    }
}

# Part 1:
set target [lsearch $napLog(map,$maxguard) $napLog(max,$maxguard)]
puts "Guard $maxguard slept for [lindex $napLog(map,$maxguard) $target] minutes in minute $target."
puts "Result is [expr {$maxguard * $target}]\n"

# Part 2:
set target [lsearch $napLog(map,$maxminguard) $napLog(max,$maxminguard)]
puts "Guard $maxminguard was asleep at minute $target $napLog(max,$maxminguard) times."
puts "Result is [expr {$maxminguard * $target}]\n"

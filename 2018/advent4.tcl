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
set gPattern {\[(.+)] Guard #([0-9]+) begins shift}
set sPattern {\[(.+)] falls asleep}
set wPattern {\[(.+)] wakes up}
set dateFmt "%Y-%m-%d %H:%M"

foreach line $inL {
    # Get the parameters
    # timestamps are in seconds, so / 60
    if {![regexp -- $gPattern $line match timestamp guardNum]} {
        if {![regexp -- $sPattern $line match timestamp]} {
            if {![regexp -- $wPattern $line match timestamp]} {
                puts "unparsable line $line"
                exit
            } else {
                # Wakeup
                set wakemin [scan [clock format [clock scan $timestamp -format $dateFmt] -format "%M"] "%d"]
                incr guardsleeps(total,$guardNum) [expr {$wakemin - $sleepmin}]
                for {set idx $sleepmin} {$idx < $wakemin} {incr idx} {
                    set guardsleeps(map,$guardNum) [lreplace $guardsleeps(map,$guardNum) \
                            $idx $idx [expr {[lindex $guardsleeps(map,$guardNum) $idx] + 1}]]
                }
            }
        } else {
            # Sleep
            set sleepmin [scan [clock format [clock scan $timestamp -format $dateFmt] -format "%M"] "%d"]
        }
    } else {
        # NewGuard
        if {![info exists guardsleeps(map,$guardNum)]} {
            # new guards get new maps
            set guardsleeps(map,$guardNum) [lrepeat 60 0]
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

foreach guard [array names guardsleeps total,*] {
    set guardNum [string range $guard 6 end]
    # Part 1: Find the guard with the highest total time
    if {$guardsleeps(total,$guardNum) > $maxsleep} {
        set maxsleep $guardsleeps(total,$guardNum)
        set maxguard $guardNum
    }
    # Part 2: Find the guard with the highest individual minute total
    set guardsleeps(max,$guardNum) [::math::max {*}$guardsleeps(map,$guardNum)]
    if {$guardsleeps(max,$guardNum) > $maxminute} {
        set maxminute $guardsleeps(max,$guardNum)
        set maxminguard $guardNum
    }
}

# Part 1:
set target [lsearch $guardsleeps(map,$maxguard) $guardsleeps(max,$maxguard)]
puts "Guard $maxguard slept for [lindex $guardsleeps(map,$maxguard) $target] minutes in minute $target."
puts "Result is [expr {$maxguard * $target}]\n"

# Part 2:
set target [lsearch $guardsleeps(map,$maxminguard) $guardsleeps(max,$maxminguard)]
puts "Guard $maxminguard was asleep at minute $target $guardsleeps(max,$maxminguard) times."
puts "Result is [expr {$maxminguard * $target}]\n"

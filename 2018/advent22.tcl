#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Day 22: Mode Maze

# Input is given:
set depth 10689
set target {11 722}

##Test data
#set depth 510
#set target {10 10}

# Build a map of erosion indices, which hashmap x,y coords to an erosion level
# to a terrain type.
lassign $target tgtX tgtY
proc mapVal {x y} {
    if {(($x == 0) && ($y == 0)) || (($x == $::tgtX) && ($y == $::tgtY))} {
        set geoindex 0
    } elseif {$y == 0} {
        set geoindex [expr {$x * 16807}]
    } elseif {$x == 0} {
        set geoindex [expr {$y * 48271}]
    } else {
        set geoindex [expr {($::map(erosion,[expr {$x - 1}],$y) *
                             $::map(erosion,$x,[expr {$y - 1}]))}]
    }
    set ::map(erosion,$x,$y)  [expr {($geoindex + $::depth) % 20183}]
    set ::map(type,$x,$y) [expr {$::map(erosion,$x,$y) % 3}]
}
for {set y 0} {$y <= $tgtY * 2} {incr y} {
    for {set x 0} {$x <= $tgtX + $tgtY} {incr x} {
        mapVal $x $y
    }
}

# print map
for {set y 0} {$y <= $tgtY + 5} {incr y} {
    for {set x 0} {$x <= $tgtX + 5} {incr x} {
        puts -nonewline [lindex {"." "=" "|"} $::map(type,$x,$y)]
    }
    puts ""
}

# Part 1:
# Compute risk index (sum of types) for rectangle from 0,0 to target, inclusive.
for {set y 0} {$y <= $tgtY} {incr y} {
    for {set x 0} {$x <= $tgtX} {incr x} {
        incr riskLevel $::map(type,$x,$y)
    }
}
puts "Risk level from 0,0 to $tgtX,$tgtY:  $riskLevel"

# Part 2:
# Traverse to the target as fast as possible.  Regions require tools:
# (0) Rocky requires Climbing Gear or Torch.  Cannot use Neither.
# (1) Wet requires Climbing Gear or Neither.  Cannot use Torch.
# (2) Narrow requires Torch or Neither.  Cannot use Climbing Gear.
# With the right tool, transit takes 1 minute.  Changing tools takes
# 7 minutes.
proc dumpQueue {} {
    puts ""
    puts "Step $::curTime  Position: $::position History $::history"
    foreach step $::queueL {
        puts [format "    t: %2d p: %7s  h=> %s" {*}$step]
    }
    puts ""
}
array set cost {
    "0,0,C" {1 C} "0,0,T" {1 T} "0,1,C" {1 C} "0,1,T" {8 C} "0,2,C" {8 T} "0,2,T" {1 T}
    "1,0,C" {1 C} "1,0,N" {8 C} "1,1,C" {1 C} "1,1,N" {1 N} "1,2,C" {8 N} "1,2,N" {1 N}
    "2,0,T" {1 T} "2,0,N" {8 T} "2,1,T" {8 N} "2,1,N" {1 N} "2,2,T" {1 T} "2,2,N" {1 N}
}
# Finding the target requires a torch, which must be switched to if not
# already equipped.
lappend target "T"
# Start at 0,0 with the torch.
set queueL [list [list 0 0 {0 0 T} {}]]
set foundTime 9999
set curTime 0
set oldTime 0
while {$foundTime >= $curTime} {
    lassign [lindex $queueL 0] astar curTime position history
    lassign $position x y tool
    set mdist [expr {abs($x - $tgtX) + abs($y - $tgtY)}]
#dumpQueue
    if {($x < 0) || ($y < 0)} {
        # Negative indices are "solid rock"
        set queueL [lrange $queueL 1 end]
        continue
    }
    if {"$tgtX,$tgtY" eq "$x,$y"} {
        if {$tool eq "T"} {
            puts "Alert the media!"
            set foundTime $curTime
        }
        # else: switch to final torch
        lappend history $curTime $position
        lappend queueL [list [expr $curTime + 7] [expr $curTime + 7] [list $x $y T] $history]
        set queueL [lsort -integer -index 0 [lrange $queueL 1 end]]
        continue
    }
    if {[info exists timeat($x,$y,$tool)]} {
        if {$curTime >= $timeat($x,$y,$tool)} {
            # Another path's been here faster.
            set queueL [lrange $queueL 1 end]
            continue
        }
    }
    set timeat($x,$y,$tool) $curTime
    lappend history $curTime $position
    if {![info exists timeat([expr $x+1],$y,$tool)] || $timeat([expr $x+1],$y,$tool) > $curTime} {
        foreach {timecost newtool} $cost($map(type,$x,$y),$map(type,[expr $x+1],$y),$tool) {
            lappend queueL [list [expr $curTime + $timecost + $mdist] [expr $curTime + $timecost] \
                                [list [expr $x+1] $y $newtool] $history]
        }
    }
    if {![info exists timeat($x,[expr $y+1],$tool)] || $timeat($x,[expr $y+1],$tool) > $curTime} {
        foreach {timecost newtool} $cost($map(type,$x,$y),$map(type,$x,[expr $y+1]),$tool) {
            lappend queueL [list [expr $curTime + $timecost + $mdist] [expr $curTime + $timecost] \
                                [list $x [expr $y+1] $newtool] $history]
        }
    }
    if {($x > 0) && (![info exists timeat([expr $x-1],$y,$tool)] || $timeat([expr $x-1],$y,$tool) > $curTime)} {
        foreach {timecost newtool} $cost($map(type,$x,$y),$map(type,[expr $x-1],$y),$tool) {
            lappend queueL [list [expr $curTime + $timecost + $mdist] [expr $curTime + $timecost] \
                                [list [expr $x-1] $y $newtool] $history]
        }
    }
    if {($y > 0) && (![info exists timeat($x,[expr $y-1],$tool)] || $timeat($x,[expr $y-1],$tool) > $curTime)} {
        foreach {timecost newtool} $cost($map(type,$x,$y),$map(type,$x,[expr $y-1]),$tool) {
            lappend queueL [list [expr $curTime + $timecost + $mdist] [expr $curTime + $timecost] \
                                [list $x [expr $y-1] $newtool] $history]
        }
    }
    set queueL [lsort -integer -index 0 [lrange $queueL 1 end]]
}
puts "$curTime:  $position <==> $target"

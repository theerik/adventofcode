#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math

# Read the input file
set fhandle [open "advent23.txt"]
#set fhandle [open "temp3.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 23: Experimental Emergency Teleportation
#
# Input: a list of nanobots of the form:
# pos=<-1,4,4>, r=9
# where pos is an x,y,z tuple and r is the range of its radio.
foreach line [split $input "\n"] {
    scan $line "pos=<%d,%d,%d>, r=%d" x y z r
    lappend botL [list $r $x $y $z]
}

# Part 1:
# Find the nanobot with the largest radio range.
# How many nanobots are in range of it?
set sortL [lsort -integer -index 0 $botL]
lassign [lindex $sortL end] longR longX longY longZ
lassign {0 0 0 0 0 0 0 0} xmin ymin zmin rmin xmax ymax zmax rmax
foreach bot $botL {
    lassign $bot r x y z
    set distance [expr {abs($x - $longX) + abs($y - $longY) + abs($z - $longZ)}]
    if {$distance <= $longR} {
        incr inRange
    }
    # as long as we're iterating the bot list, pick up min/max per axis.
    if {$x < $xmin} {set xmin $x}
    if {$y < $ymin} {set ymin $y}
    if {$z < $zmin} {set zmin $z}
    if {$r < $rmin} {set rmin $r}
    if {$x > $xmax} {set xmax $x}
    if {$y > $ymax} {set ymax $y}
    if {$z > $zmax} {set zmax $z}
    if {$r > $rmax} {set rmax $r}
}
puts "Nanobot at ($longX,$longY,$longZ) has the longest-range radio ($longR). \
      \nThere are $inRange bots within range."

# Part 2:
# For all points in the cloud, find the point in range of the most nanobots
puts "max range is X: $xmin-$xmax Y: $ymin-$ymax Z: $zmin-$zmax"

# Checking if a bot can be seen from anywhere in the cube.  This means the
# bot's radius plus some distance per axis up to the cube's size.  But we
# can't just use 3x size, since some axes may be on-axis, and contribute
# only
proc botInCube {bot cube} {
    lassign $bot botR botX botY botZ
    lassign $cube cubeR cubeX cubeY cubeZ
    set range [tcl::mathop::+ {*}[lmap axis {X Y Z} { expr {min($cubeR, abs([set bot$axis] - [set cube$axis]) )} }] $botR]
    return [expr {(abs($botX - $cubeX) + abs($botY - $cubeY) + abs($botZ - $cubeZ)) <= $range ? 1 : 0}]
}
proc log2 {n} {
    # I'm sure it's in some package or library, but damned if I can find it
    set b [format "%b" $n]
    set log2 [string length [string trimleft $b "0"]]
    return [expr {$log2 - 1}]
}
proc countBotsInCube {cube botL} {
    foreach bot $botL {
        incr count [botInCube $bot $cube]
    }
    return $count
}

set cubesize [expr {1 << (int([log2 [::math::max $xmax $ymax $zmax]]) + 1)}]
puts "Starting with cubes $cubesize on a side...."
set searchQueueL [list [list [llength $botL] $cubesize 0 0 0] ]
set maxScore 0
# List is sorted, so if there's no cube left to search that can't beat the
# max found so far, we're done.
while {$maxScore <= [lindex [lindex $searchQueueL 0] 0]} {
    # pop cube
    set searchCube [lindex $searchQueueL 0]
#puts "searchCube is $searchCube"
    # break it into eight subcubes.  Search each for counts and put each
    # new subcount and subcube back onto the queue.
    set opL {"+" "+" "+" "+" "+" "-" "+" "-" "+" "+" "-" "-" \
             "-" "+" "+" "-" "+" "-" "-" "-" "+" "-" "-" "-" }
    lassign $searchCube oldScore oldSize oldX oldY oldZ
    # Check for end condition - Queue is sorted, so
    if {$oldSize == 0} {
        if {$oldScore > $maxScore} {
            set maxScore $oldScore
            set maxL [list $searchCube]
        } elseif {$oldScore == $maxScore} {
            lappend maxL $searchCube
        }
        # else not the best, so nothing to do.
        # Nothing smaller to test - pitch it.
        set searchQueueL [lrange $searchQueueL 1 end]
        continue
    }

#puts "old: $oldScore $oldSize $oldX $oldY $oldZ"
    set r [expr {$oldSize / 2}]
    # Center was getting dropped on last iteration:
    if {$r == 0} {
        set dr 1
        set count [countBotsInCube [list $r $oldX $oldY $oldZ] $botL]
#if {($r == 0) && ($count > 3)} {puts "N C: $count $r $oldX $oldY $oldZ"}
        lappend searchQueueL [list $count $r $oldX $oldY $oldZ]
    } else {
        set dr $r
    }
    foreach {op1 op2 op3} $opL {
        set x [expr $oldX $op1 $dr]
        set y [expr $oldY $op2 $dr]
        set z [expr $oldZ $op3 $dr]
        set count [countBotsInCube [list $r $x $y $z] $botL]
#if {($r == 0) && ($count > 3)} {puts "new: $count $r $x $y $z"}
        lappend searchQueueL [list $count $r $x $y $z]
    }
    # Sort after each round to keep the best ones on top
    set searchQueueL [lsort -decreasing -integer -index 0 [lrange $searchQueueL 1 end]]
#puts "Queue is $searchQueueL"
}

puts "Found: $maxScore, in these points: $maxL"

proc manDist {s r x y z} {return [expr {abs($x) + abs($y) + abs($z)}]}
proc manComp {bot1 bot2} {
    set m1 [manDist {*}$bot1]
    set m2 [manDist {*}$bot2]
    return [expr {($m1 < $m2) ? -1 : (($m1 > $m2) ? 1 : 0) }]
}
#puts "unsorted: [lsort -integer -command manComp $maxL]"
#foreach bot $maxL {puts "bot: $bot  Dist: [manDist {*}$bot]"}
#puts "Sorted:"
#foreach bot [lsort -integer -command manComp $maxL] {puts "bot: $bot  Dist: [manDist {*}$bot]"}
foreach posn [lsort -integer -command manComp $maxL] {
    puts "Position is $posn, at distance [manDist {*}$posn]"
}






#proc numInRange {inx iny inz botL} {
#    set inRange 0
#    foreach bot $botL {
#        lassign $bot r x y z
#        set distance [expr {abs($x - $inx) + abs($y - $iny) + abs($z - $inz)}]
#        if {$distance <= $r} {
#            incr inRange
#        }
#    }
#    return $inRange
#}
#set maxRange 0
#foreach bot $botL {
#puts $bot
#    lassign $bot botr botx boty botz
#    for {set z [expr {$botz - $botr}]} {$z <= ($botz + $botr)} {incr z} {
#        for {set y [expr {$boty - $botr}]} {$y <= [expr {$boty + $botr}]} {incr y} {
#            for {set x [expr {$botx - $botr}]} {$x <= [expr {$botx + $botr}]} {incr x} {
#                incr rangeA($x,$y,$z)
#                if {$rangeA($x,$y,$z) > $maxRange} {
#                    set maxRange $rangeA($x,$y,$z)
#                    set maxPos [list $x $y $z]
#                }
#            }
#puts -nonewline "."
#        }
##puts ""
#    }
#}
##parray rangeA
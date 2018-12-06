#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
set fhandle [open "advent3.txt"]
set input [read -nonewline $fhandle]
close $fhandle
set inL [split $input "\n"]

# Day 3: No Matter How You Slice It
# Part 1:
# Determine how many square inches of fabric are claimed by more than one elf.
# For a set of inputs formatted as follows:
# "#<claim_num> @ <xorigin,yorigin>: <xsize>x<ysize>"
# determine which square inches of fabric are claimed by this claim, and from
# that track how many potential squares are claimed twice or more.
# Part 2:
# Find the sole claim that doesn't conflict
set pattern {#([0-9]+) @ ([0-9]+),([0-9]+): ([0-9]+)x([0-9]+)}
foreach line $inL {
    # Get the parameters
    if {![regexp -- $pattern $line -> claimNum xOrg yOrg xSize ySize]} {
        puts "could not parse claim: $line"
        exit
    }
    # Mark the claim
    for {set x $xOrg} {$x < ($xOrg + $xSize)} {incr x} {
        for {set y $yOrg} {$y < ($yOrg + $ySize)} {incr y} {
            lappend squareCount($x,$y) $claimNum
        }
    }
}
# Count all squares with 2 or more claims
foreach addr [array names squareCount] {
    if {[llength $squareCount($addr)] > 1} {
        # for Part 1:
        incr overCount
        # for Part 2:
        foreach claim $squareCount($addr) {
            set conflicts($claim) true
        }
    }
}
puts "The number of overclaimed squares is $overCount"
for {set claim 1} {$claim <= [llength $inL]} {incr claim} {
    if {![info exists conflicts($claim)]} {
        puts "Claim $claim is not in conflict."
    }
}



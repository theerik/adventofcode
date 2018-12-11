#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require math

# Get input from file
set fhandle [open "advent5.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 5: Alchemical Reduction
# Parse the word.  Adjacent letters of the same base but opposite cases
# (such as A & a) are removed, recursively examining the new character pairing
# made by the removal.

# Part 1: React the Polymer
# Find the remaining length after fully reacting the polymer.

# Create an output string.  We will transfer characters to it one at a time.
# We compare the last letter of the output to the first letter of the remainder.
# If they react, both are removed and we do it again until they don't react.
# Then move on to the next letter.

# We end up needing this in both parts, so make a proc out of it.
proc react {polyin} {
    set remainL [split $polyin ""]
    set idx 0

    while {$idx < [llength $remainL]} {
        lassign [lrange $remainL $idx $idx+1] base1 base2
        if {([string tolower $base1] eq [string tolower $base2]) &&
                ($base1 ne $base2)} {
            set remainL [lreplace $remainL[set remainL {}] $idx $idx+1]
            incr idx -1     ;# Re-evaluate base formed by newly adjacent pair
        } else {
            incr idx
        }
    }
    return [llength $remainL]
}
puts "Ending length: [react $input]"

# Part 2: Refine the polymer
# One of the types (a/A or b/B or ...) is preventing fuller collapse.  Find
# out which type can be removed to produce the shortest result.  Return that
# length.
# Loop over the letters from A to Z (in ascii value to loop), create a string
# with that letter and its lowercase removed, and find its length.
set lengthL {}
for {set letter 0x41} {$letter < 0x5B} {incr letter} {
    set mapStr [format "%c \"\" %c \"\"" $letter [expr $letter + 0x20]]
    set newPoly [string map $mapStr $input]
    lappend lengthL [react $newPoly]
    puts -nonewline [format "%c" $letter]
    flush stdout
}
puts "\n\nShortest polymer: [::math::min {*}$lengthL]"

#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Get input from file
set fhandle [open "advent12.txt"]
#set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 12: Subterranean Sustainability
# Input: a string representing pots numbered from 0 up.  "#" contains a plant;
# "." does not.
# Following: a list of rules.  Each pot will contain a plant on the next step
# based on its own content plus the two pots to the left and two to the right,
# represented as a 5-char string, a marker, and a result (e.g.. ".#.#." => .)
foreach line [split $input "\n"] {
    switch -regexp -matchvar matchL -- $line {
        {[a-z]+: ([\.\#]+)} {
            set potS [lindex $matchL 1]
        }
        {([\.\#]+) => ([\.\#])} {
            set rules([lindex $matchL 1]) [lindex $matchL 2]
        }
    }
}
puts "len [string length $potS]"

proc generate {potS} {
    set in "...$potS....."
    set outS ""
    for {set idx 0} {$idx < [string length $potS]+4} {incr idx} {
        set pots [string range $in $idx $idx+4]
        append outS $::rules($pots)
    }
    return "[string trimright $outS "."].."
}

# Part 1:
# After 20 generations, what is the sum of the numbers of all pots which
# contain a plant?
# Note that every generation, the list grows by 2 pots on each end, so there's
# an offset to the indices when summing.
set numGens 20 ;# 50000000000
puts "potS: $potS"
for {set idx 0} {$idx < $numGens} {incr idx} {
    set potS [generate $potS]
    incr offset [expr {2 - ([string length $potS] - [string length [string trimleft $potS "."]])}]
puts "lL: [string length $potS]  trimmed: [string length [string trimleft $potS "."]] offset: $offset "
    set potS [string trimleft $potS "."]
    puts "[string repeat " " [expr {6 - $offset}]]$potS   offset $offset ([expr {2 - ([string length $potS] - [string length [string trimleft $potS "."]])}])"
}
foreach pot [lsearch -all [split $potS ""] "#"] {
    incr total $pot
}
puts "After 20 generations, $total"
# [string repeat " " [expr {$numGens - $idx - 1}]]
# [expr {$pot - $numGens}]
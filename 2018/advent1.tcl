#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Get input from file
set fhandle [open "advent1.txt"]
set input [read -nonewline $fhandle]
close $fhandle
set inL [split $input "\n"]

# Part 1: Find comprehension sum
set outsum [tcl::mathop::+ {*}$inL]
puts "Final frequency: $outsum"

# Part 2: Find first frequency seen twice
set curFreq 0
set found false
while {!$found} {
    foreach freq $inL {
        lappend seenL $curFreq
        incr curFreq $freq
        if {$curFreq in $seenL} {
            set found true
            puts "First frequency seen twice: $curFreq"
            break
        }
    }
}


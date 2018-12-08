#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require struct::set

# Get input from file
#set fhandle [open "advent7.txt"]
set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 7: The Sum of Its Parts
#
# Given: steps in a task represented by letters, read an input that defines
# which steps precede other steps, e.g.:
# "Step A must be finished before step B can begin."

# This feels like a tree, but since children can have multiple parents it is
# not a proper tree, but a directed mesh graph.  To store it, I will use an
# array to directly add to lists of parents and children for each step.
# If another form is more appropriate later, it can be quickly converted.
set inL [lsort [split $input "\n"]]
foreach line $inL {
    regexp {Step ([A-Z]) must be finished before step ([A-Z]) can begin.} $line -> parent child
    lappend stepMap($child,parents) $parent
    lappend stepMap($parent,children) $child
    # Maintain a list of known steps
    ::struct::set add stepL $parent
    ::struct::set add stepL $child
}

# Part 1:
# Determine the order in which steps should be completed.  All predecessors
# must be complete before a given step can be completed; if there is more
# than one step ready at any given moment, they should be completed in
# alphabetical order.

# Find the steps without parents, and put them in a list of ready tasks.
foreach step $stepL {
    if {![info exists $stepMap($step,parents)]} {
        lappend taskL $step
    }
}

# Process the task list.  N.B. that if multiple steps are ready, they should
# be completed in alpha order.  Take the first step, mark it complete, and
# check all its children.  For each child, if all parents are in the done list,
# add that step to the task list.
set doneL {}
while {[llength $doneL] != [llength $stepL]} {
    # If multiple tasks are ready, do them in alphabetical order
    set taskL [lsort $taskL]
    set current [lindex $taskL 0]
    set taskL [lreplace $taskL 0 0]
    lappend doneL $current
    foreach child $stepMap($current,chilren) {
        foreach parent {$stepMap($child,parents)} {
            # If the parent isn't done, break from the INNER LOOP only
            if {!($parent in $doneL)} break
        }
        # No parents weren't done - add to ready task list
        lappend taskL $current
    }
}
puts "The order of steps should be: [join $doneL ""]"




#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require struct::set

# Get input from file
set fhandle [open "advent7.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 7: The Sum of Its Parts
#
# Given: steps in a task represented by letters, read an input that defines
# which steps precede other steps, e.g.:
# "Step A must be finished before step B can begin."

# This feels like a tree, but since children can have multiple parents it is
# not a proper tree, but a directed mesh graph.  To store it, I will use an
# array to maintain lists of parents and children for each node.
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
# Determine the order in which instruction steps should be completed.
# All predecessors must be complete before a given step can be completed;
# if there is more than one step ready at any given moment, they should be
# completed in alphabetical order.

# Find the steps without parents, and put them in a list of ready tasks.
lmap step $stepL {if {![info exists stepMap($step,parents)]} {lappend taskL $step}}
set doneL {}

# Process the task list.  N.B. that if multiple steps are ready, they should
# be completed in alpha order.  Take the first step, mark it complete, and
# check all its children.  For each child, if all parents are in the done list,
# add that step to the task list.
while {[llength $doneL] != [llength $stepL]} {
    # If multiple tasks are ready, do them in alphabetical order
    set taskL [lsort $taskL]
    # "Complete" the task
    set current [lindex $taskL 0]
    set taskL [lreplace $taskL 0 0]
    lappend doneL $current
    # Process children
    if [info exists stepMap($current,children)] {
        foreach child $stepMap($current,children) {
            if {$child in $doneL} continue
            if {[::struct::set subsetof $stepMap($child,parents) $doneL]} {
                lappend taskL $child
            }
        }
    }
}
puts "\nThe order of steps should be: [join $doneL ""]"

# Part 2:
# Determine how long will it take to assemble the sleigh.
# Steps now take time - 60 seconds + 1 second * <offset of letter in alphabet>
# E.g., A = 61, B = 62, ..., Z = 86.  Helper proc:
proc taskDuration {step} {return [expr {([scan $step %c] - 0x40) + 60}] }
# Four elves will be helping work on tasks if they're ready, for a total of
# five (5) workers.  Workers can only work on tasks if they're ready, and if
# the worker has finished their prior task (duh).

# We will be using 4 lists: a to-do list (stepL/stepMap), a list of ready tasks
# that are available to begin (taskL), a list of tasks currently being worked
# on (activeL), and a list of completed tasks (doneL).  The active list will
# consist of tuples, with each tuple containing the end time and the step ID.
# Because we don't need to know in the end who did which task, we will not be
# tracking tasks per worker.

# Find the steps without parents, and put them in a list of ready tasks.
lmap step $stepL {if {![info exists stepMap($step,parents)]} {lappend taskL $step}}
set currTime 0
set doneL {}
set activeL {}

while {[llength $doneL] != [llength $stepL]} {
    # Allocate new tasks if possible, up to the limit of 5 workers.
    while {([llength $taskL] > 0) && ([llength $activeL] <= 5)} {
        set newstep [lindex $taskL 0]
        set taskL [lreplace $taskL 0 0]
        lappend activeL [list [expr {$currTime + [taskDuration $newstep]}] $newstep]
    }

    # Process the next complete task.
    set complete [lindex $activeL 0]
    set activeL [lreplace $activeL 0 0]
    set currTime [lindex $complete 0]
    set current [lindex $complete 1]
    lappend doneL $current

    # Process children
    if [info exists stepMap($current,children)] {
        foreach child $stepMap($current,children) {
            if {$child in $doneL} continue
            if {[::struct::set subsetof $stepMap($child,parents) $doneL]} {
                lappend taskL $child
            }
        }
    }

    # Sort the active list by end time
    set activeL [lsort -index 0 -integer $activeL]
}
puts "Total duration was: $currTime"
puts "Actually completed order was [join $doneL ""]"


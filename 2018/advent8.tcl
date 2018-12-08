#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Get input from file
set fhandle [open "advent8.txt"]
#set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle
set inL [split $input]

# Day 8: Memory Maneuver
# Given input data that describes a tree where each node has 0 or more
# children and some metadata.

# Specifically, a node consists of:
# - A header, which is always exactly two numbers:
#    - The quantity of child nodes.
#    - The quantity of metadata entries.
# - Zero or more child nodes (as specified in the header).
# - One or more metadata entries (as specified in the header).

# Part 1:
# Sum all the metadata.
# This is easily accumulated as we build.
# We build the tree as a nested dict, and use recursion to walk the input data.
proc buildTree {depthL remainL} {
    global treeD totalSum
    set remainL [lassign $remainL numChildren numMetas]
    for {set childNum 1} {$childNum <= $numChildren} {incr childNum} {
        set remainL [buildTree [list {*}$depthL $childNum] $remainL]
    }
    set metas [lrange $remainL 0 $numMetas-1]
    eval {dict set treeD {*}$depthL meta $metas}
    set totalSum [expr {$totalSum + [tcl::mathop::+ {*}$metas]}]
    return [lrange $remainL $numMetas end]
}

set totalSum 0
set treeD [dict create]
buildTree {} $inL

puts "Total sum is $totalSum"

# Part 2:
# We define the "value" of a node differently depending if it has children.
# - If a node has no child nodes, its value is the sum of its metadata.
# - If a node has children, its value is the sum of the child nodes whose
#   numbers are in the metadata.  E.g., if metadata is {1 3 1}, its value
#   is the (Vchild1 + Vchild3 + Vchild1).  If the child does not exist,
#   skip and move on.

proc findValue {inDict} {
    set value 0
    if {[llength [dict keys $inDict]] > 1} {
        # It has children.  Add up the ones in the meta that exist.
        foreach child [dict get $inDict meta] {
            if [dict exists $inDict $child] {
                incr value [findValue [dict get $inDict $child]]
            }
        }
    } else {
        set value [::tcl::mathop::+ {*}[dict get $inDict meta]]
    }
    return $value
}
puts "Value of root node is [findValue $treeD]"

# After finishing, I realized that I overbuilt this.  I was expecting more
# of a challenge in part 2. :)  That will come later, I'm sure.
# The entire dict was unnecessary; it could have just been accumulated and
# returned in the recursion.
proc solveIt {dataL} {
    set value 0
    set valL {0}
    set metaSum 0
    set dataL [lassign $dataL numChildren numMetas]
    for {set childNum 1} {$childNum <= $numChildren} {incr childNum} {
        lassign [solveIt $dataL] dataL childMeta childVal
        incr metaSum $childMeta
        lappend valL $childVal
    }
    set metas [lrange $dataL 0 $numMetas-1]
    incr metaSum [tcl::mathop::+ {*}$metas]
    if {$numChildren} {
        foreach child $metas {
            incr value [expr {[lindex $valL $child] eq {} ? 0 : [lindex $valL $child]}]
        }
    } else {
        set value [tcl::mathop::+ {*}$metas]
    }
    return [list [lrange $dataL $numMetas end] $metaSum $value]
}

lassign [solveIt $inL] outL totalMetas rootValue
puts "\nDirect recursion: totalMetaSum = $totalMetas \trootNodeValue = $rootValue"

#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
set fhandle [open "advent16.txt"]
#set fhandle [open "temp.txt"]
set input [read -nonewline $fhandle]
close $fhandle

proc lremove {lname elemval} {
    upvar $lname lst
    set idx [lsearch $lst $elemval]
    if {$idx == -1} {return false}
    set lst [lreplace $lst $idx $idx]
    return true
}

# Day Day 16: Chronal Classification
#
# Input is in two parts.  The first part is a series of observations:
# "Before:  [0, 3, 0, 2]"
# "13 0 0 3"
# "After:  [0, 3, 0, 0]"
# ""
# where the vector "[...]" is the state of registers 0, 1, 2, & 3 before and
# after the central line, the instruction, is executed.  Each instruction is
# made up of four fields:  opcode, A (source 1), B (source 2), & C (destination).
# The second part is a test program consisting of a list of instructions, and
# is not used in part 1.
# I inserted a marker between the halves for simplicity...
set testProg false
foreach line [split $input "\n"] {
    switch -glob --$line {
        *Test*  {
            # Switch to just recording for later
            set testProg true
        }
        *Before*    {
            scan $line "Before: \[%d, %d, %d, %d\]" r0 r1 r2 r3
            set regBefore [list $r0 $r1 $r2 $r3]
        }
        *After* {
            scan $line "After: \[%d, %d, %d, %d\]" r0 r1 r2 r3
            set regAfter [list $r0 $r1 $r2 $r3]
            lappend exampleL [list $regBefore $testInstr $regAfter]
        }
        {*[0-9 ]}  {
            set testInstr [split $line " "]
            if {$testProg} {
                lappend programL $testInstr
            }
        }
        default {
            # It's a blank line.  If I hadn't inserted a marker, I'd use
            # this spot to count three blank lines to separate the input halves.
        }
    }
}
puts "there were [llength $exampleL] example instructions, "
puts "and [llength $programL] instructions in the test program"

# There are 16 possible opcodes, but the assignment from number to operation
# is not given.  The opcodes are:
set opCodeL {"addr" "addi" "mulr" "muli" "banr" "bani" "borr" "bori" \
             "setr" "seti" "gtir" "gtri" "gtrr" "eqir" "eqri" "eqrr"}
# Opcodes ending in r treat B as a register; opcodes ending in i treat B as
# an immediate value.  Comparisons end in two [ir] letters, denoting
# reg/immed for A and B.  Sets ignore B and only use A.

# Process an instruction with known opcode
proc operate {instr inRegs} {
    lassign $instr opcode src1 src2 dest
    lassign $inRegs r0 r r2 r3
    set outRegs $inRegs
    switch $opcode {
        "addr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] + [lindex $inRegs $src2]}] }
        "addi"  { lset outRegs $dest [expr {[lindex $inRegs $src1] + $src2}] }
        "mulr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] * [lindex $inRegs $src2]}] }
        "muli"  { lset outRegs $dest [expr {[lindex $inRegs $src1] * $src2}] }
        "banr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] & [lindex $inRegs $src2]}] }
        "bani"  { lset outRegs $dest [expr {[lindex $inRegs $src1] & $src2}] }
        "borr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] | [lindex $inRegs $src2]}] }
        "bori"  { lset outRegs $dest [expr {[lindex $inRegs $src1] | $src2}] }
        "setr"  { lset outRegs $dest [lindex $inRegs $src1] }
        "seti"  { lset outRegs $dest $src1 }
        "gtir"  { lset outRegs $dest [expr {$src1 > [lindex $inRegs $src2]}] }
        "gtri"  { lset outRegs $dest [expr {[lindex $inRegs $src1] > $src2}] }
        "gtrr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] > [lindex $inRegs $src2]}] }
        "eqir"  { lset outRegs $dest [expr {$src1 == [lindex $inRegs $src2]}] }
        "eqri"  { lset outRegs $dest [expr {[lindex $inRegs $src1] == $src2}] }
        "eqrr"  { lset outRegs $dest [expr {[lindex $inRegs $src1] == [lindex $inRegs $src2]}] }
    }
    return $outRegs
}
# See if two sets of registers match.
proc regsMatch {regA regB} {
    if {[llength $regA] != [llength $regB]} {
        error "regsMatch bad input: \[$regA\] <-> \[$regB\]"
    }
    foreach r1 $regA r2 $regB {
        if {$r1 != $r2} {return false}
    }
    return true
}

# Part 1:
# For the example input, how many of them behave like 3 or more opcodes?
foreach example $exampleL {
    lassign $example inRegs instr outRegs
    set matchCnt 0
    foreach opcode $opCodeL {
        set ins $instr
        lset ins 0 $opcode
        set r2 [operate $ins $inRegs]
        if [regsMatch $r2 $outRegs] {
            incr matchCnt
            # Record matches for later?
            incr matchA($opcode,[lindex $instr 0])
        } else {
            incr noMatchA($opcode,[lindex $instr 0])
        }
    }
    if {$matchCnt >= 3} {
        incr multiMatch
    }
}

puts "Out of [llength $exampleL] examples, $multiMatch matched more than 3 opcodes."
puts ""

# Part 2:
# Using the samples you collected, work out the number of each opcode and
# execute the test program (the second section of your puzzle input).

# Iterate over the opcodes.  For each opcode, if the combo of opcode and number
# show up in the noMatch array, that number is out.  If it has no noMatches
# and some matches, add it to a list for the next step.
foreach opcode $opCodeL {
    for {set i 0} {$i < 16} {incr i} {
        if {[info exists noMatchA($opcode,$i)]} {
            lappend noMatchA($opcode,list) $i
        } elseif {[info exists matchA($opcode,$i)]} {
            lappend matchA($opcode,list) $i
        } else {
            puts "No examples of $opcode as value $i"
        }
    }
#    puts "$opcode: likely $matchA($opcode,list) \tnot: $noMatchA($opcode,list)"
}
# refine the list.  Iteratively, if there's only one possibility on the match
# list, that MUST be the match.  Assign that opcode and remove that number from
# all other lists.
set candL $opCodeL
set lastSize 0
while {1} {
    foreach opcode $candL {
        if {[llength $matchA($opcode,list)] == 1} {
            set num $matchA($opcode,list)
            set opcodeA($num) $opcode
            lremove candL $opcode
            unset matchA($opcode,list)
            foreach c $candL {
                if {$num in $matchA($c,list)} {
                    lremove matchA($c,list) $num
                }
            }
        }
    }
    if {[array size opcodeA] == 16} break
    if {[array size opcodeA] == $lastSize} break
    set lastSize [array size opcodeA]
}

parray opcodeA
foreach rem [array names matchA "*,list"] {
    puts "$rem: $matchA($rem)"
}
puts ""

# All opcodes resolved.  Now, iterate over the instructions.
set inRegs {0 0 0 0}
foreach instr $programL {
    lset instr 0 $opcodeA([lindex $instr 0])
    set outRegs [operate $instr $inRegs]
#    puts "$instr: $inRegs -> $outRegs"
    set inRegs $outRegs
}

puts "After running, outRegs contain: $outRegs"

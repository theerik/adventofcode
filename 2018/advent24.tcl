#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Read the input file
set fhandle [open "advent24.txt"]
#set fhandle [open "temp3.txt"]
set input [read -nonewline $fhandle]
close $fhandle

# Day 24: Immune System Simulator 20XX
#
# Input: Descriptions of two armies, in groups.  E.g.:
# 989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3
# Armies are "Immune System" and "Infection"
foreach line [split $input "\n"] {
    switch -glob --$line {
        *Imm* {
            set listName immL
        }
        *Inf* {
            set listName infL
        }
        *units* {
            set vuln {}
            if {[scan $line "%d units each with %d hit points (%\[a-z ;,\]) with an attack that does %d %s damage at initiative %d" units hp vuln dmg damType init] == 2} {
                scan $line "%d units each with %d hit points with an attack that does %d %s damage at initiative %d" units hp dmg damType init
            }
            lappend $listName group[incr maxId]
            dict set unitsD group$maxId count $units
            dict set unitsD group$maxId hp $hp
            dict set unitsD group$maxId type $damType
            dict set unitsD group$maxId damage $dmg
            dict set unitsD group$maxId init $init
            foreach trait [split $vuln ";"] {
                switch -glob -- $trait {
                    *immune* {
                        scan [string trim $trait] "immune to %\[a-z ;,\]" itypeS
                        foreach type [split $itypeS ","] {
                            lappend iL [string trim $type]
                        }
                        dict set unitsD group$maxId immune $iL
                    }
                    *weak*   {
                        scan [string trim $trait] "weak to %\[a-z ,\]" wtypeS
                        foreach type [split $wtypeS ","] {
                            lappend wL [string trim $type]
                        }
                        dict set unitsD group$maxId weak $wL
                    }
                    default {error "unknown trait $trait"}
                }
            }
            foreach v {units hp vuln dmg damType init itypeS wtypeS iL wL} {unset -nocomplain $v}
        }
        default {
            if {$line ne ""} { puts "    unknown line $line" }
        }
    }
}
# For part 2, back up the initial units roster
set saveL [dict get $unitsD]
set saveD $unitsD
set saveImm $immL
set saveInf $infL

# Combat rules:
# Each unit's "effective power" is (count * damage).  If target is weak to
# attack type, damage is doubled; if target is immune, damage is 0.
# Two phases: target selection & damage resolution
# Targeting:
# Group with highest effective power goes first; initiative breaks ties (boo!)
# Attacker targets group to which it would deal most damage, after accounting
# for weaknesses but ignoring excess damage.  Ties select defender with highest
# effective power; ties after that break on init.
# Defender takes damage in whole counts of units only; the last fraction of
# damage to a defender is ignored.
proc selectTarget {atkD defL} {
    foreach group $defL {
        set groupD [dict get $::unitsD $group]
        lappend damL [list [computeAttack $atkD $groupD] [dict get $groupD effPower] [dict get $groupD init] $group]
    }
    if {[info exists damL] && [lindex [lindex [lsort -dictionary $damL] end] 0] > 1} {
        return [lindex [lindex [lsort -dictionary $damL] end] end]
    } else {
        return {}
    }
}
proc computeAttack {atkD dfnD} {
    set mpl 1
    if {([dict exists $dfnD weak]) && ([dict get $atkD type] in [dict get $dfnD weak])} {set mpl 2}
    if {([dict exists $dfnD immune]) && ([dict get $atkD type] in [dict get $dfnD immune])} {set mpl 0}
    return [expr {[dict get $atkD count] * [dict get $atkD damage] * $mpl}]
}
proc pwrSort {g1 g2} {
    upvar unitsD uD
    set p1 [dict get $uD $g1 effPower]
    set p2 [dict get $uD $g2 effPower]
    return [expr {$p1 < $p2 ? -1 : $p1 > $p2 ? 1 : 0}]
}

proc performFight {} {
    global unitsD immL infL
    # For each combat round
    set lastUnits 1
    while {0 < [llength $immL] && [llength $infL] > 0} {
        # update everyone's effective power
        dict for {group groupD} $unitsD {
            dict with groupD {
                dict set unitsD $group effPower [expr {$count * $damage}]
            }
        }
        # Everyone choose targets
        set tgtL $infL
        foreach group [lsort -decreasing -command pwrSort $immL] {
            set groupD [dict get $unitsD $group]
            dict with groupD {
                set tgt [selectTarget $groupD $tgtL]
                set idx [lsearch $tgtL $tgt]
                set tgtL [lreplace $tgtL $idx $idx]
                lappend roundL [list $init $group $tgt]
            }
        }
        set tgtL $immL
        foreach group [lsort -decreasing -command pwrSort $infL] {
            set groupD [dict get $unitsD $group]
            dict with groupD {
                set tgt [selectTarget $groupD $tgtL]
                set idx [lsearch $tgtL $tgt]
                set tgtL [lreplace $tgtL $idx $idx]
                lappend roundL [list $init $group $tgt]
            }
        }

        # Units attack in order of their initiative
        set roundL [lsort -decreasing -index 0 -integer $roundL]
        foreach attack $roundL {
            lassign $attack init atk tgt
            if {$tgt eq {}} {
                continue
            }
            set dmg [computeAttack [dict get $unitsD $atk] [dict get $unitsD $tgt]]
            set killed [expr {$dmg / [dict get $unitsD $tgt hp]}]
            set newcount [expr {[dict get $unitsD $tgt count] - $killed}]
            if {$newcount <= 0} {
                if {$tgt in $immL} {
                    set idx [lsearch $immL $tgt]
                    set immL [lreplace $immL $idx $idx]
                    dict set unitsD $tgt count 0
                } else {
                    set idx [lsearch $infL $tgt]
                    set infL [lreplace $infL $idx $idx]
                    dict set unitsD $tgt count 0
                }
            } else {
                dict set unitsD $tgt count $newcount
            }
        }
        unset roundL
        set totUnits 0
        foreach group [concat $immL $infL] {
            incr totUnits [dict get $unitsD $group count]
        }
        if {$totUnits == $lastUnits} {
            puts "Deadlock!  no units can be killed."
            return
        }
        set lastUnits $totUnits
    }
}


# Part 1:
# After the immune system fights the infection, how many units will the winning
# army have?
performFight

if {[llength $immL] > 0} {
    foreach unit $immL {
        incr finalTot [dict get $unitsD $unit count]
    }
    puts "The winning army is the Immune system, with $finalTot units left."
} else {
    foreach unit $infL {
        incr finalTot [dict get $unitsD $unit count]
    }
    puts "The winning army is the Infection, with $finalTot units left."
}
puts ""

# Part 2:
# Define a "bonus" as extra damage by all Immune System units.
# What is the minimum bonus needed for the IS to win?

set lastBonus 0
set bonus 64
set lastWin false
while {abs($lastBonus - $bonus) >= 1} {
    # restore the initial units roster and apply the current bonus
    unset unitsD
    set unitsD $saveD
    set immL $saveImm
    set infL $saveInf
    foreach group $immL {
        dict set unitsD $group damage [expr {[dict get $unitsD $group damage] + $bonus}]
    }

    # Fight it out.  Did it work?
    performFight
    set finalTot 0
    if {[llength $immL] > 0 && [llength $infL] == 0} {
        # success! roll the bonus back halfway back, and try again
        foreach unit $immL {
            incr finalTot [dict get $unitsD $unit count]
        }
        puts "The winning army is the Immune system, with $finalTot units left at bonus $bonus."
        set rb [expr {-abs($bonus - $lastBonus) / 2}]
        set lastBonus $bonus
        incr bonus $rb
        set lastWin true
    } elseif {[llength $infL] > 0 && [llength $immL] == 0} {
        # failure! double the bonus and try again.
        foreach unit $infL {
            incr finalTot [dict get $unitsD $unit count]
        }
        puts "The winning army is the Infection, with $finalTot units left at bonus $bonus."
        set rb [expr {$lastWin ? abs($bonus - $lastBonus) / 2 : abs($bonus - $lastBonus) * 2}]
        set lastBonus $bonus
        incr bonus $rb
        set lastWin false
    } else {
        # Deadlock!
        puts "Deadlock at bonus $bonus (lb: $lastBonus)"
        set rb [expr {abs($bonus - $lastBonus) / 2}]
        set oldBonus $lastBonus
        set lastBonus $bonus
        incr bonus $rb
        if {$bonus == $oldBonus} {
            puts "Oscillating - time to stop"
            exit
        }
        set lastWin false
    }
    puts ""
    puts ""
}
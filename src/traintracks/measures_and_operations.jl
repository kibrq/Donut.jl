
module MeasuresAndOperations

export collapse_branch!, pullout_branches!, pull_switch_apart!, delete_two_valent_switch!, add_switch_on_branch!, peel!, fold!, split_trivalent!, fold_trivalent!, renamebranch!, whichside_to_peel

using Donut.TrainTracks
using Donut.TrainTracks: BranchIterator
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: _allocatemore!, _setmeasure!
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps
using Donut.TrainTracks.Operations: execute_elementaryop!
import Donut.TrainTracks.Operations: pullout_branches!

using Donut.Constants: FORWARD, BACKWARD

function updatemeasure_pullout_branches!(tt_afterop::TrainTrack,
    measure::Measure, newbranch::Int)
    if newbranch > length(measure.values)
        _allocatemore!(measure, newbranch)
    end
    sw = branch_endpoint(tt_afterop, newbranch)
    newvalue = outgoingmeasure(tt_afterop, measure, -sw)
    _setmeasure!(measure, newbranch, newvalue)
end


function updatemeasure_collapse!(measure::Measure, collapsedbranch::Int)
    _setmeasure!(measure, collapsedbranch, 0)
end

function updatemeasure_deletebranch!(measure::Measure, deletedbranch::Int)
    if branchmeasure(measure, deletedbranch) != 0
        error("Cannot delete branch $(deletedbranch), because its measure is not zero.")
    end
end

function updatemeasure_renamebranch!(measure::Measure, oldlabel::Int, newlabel::Int)
    value = branchmeasure(measure, oldlabel)
    _setmeasure!(measure, oldlabel, 0)
    _setmeasure!(measure, newlabel, value)
end



function collapse_branch!(tt::TrainTrack, branch::Int, measure::Measure)
    collapse_branch!(tt, branch)
    updatemeasure_collapse!(measure, branch)
end

function pullout_branches!(iter::BranchIterator, measure::Measure)
    new_sw, new_br = pullout_branches!(iter)
    updatemeasure_pullout_branches!(iter.tt, measure, new_br)
    new_sw, new_br
end

function pull_switch_apart!(tt::TrainTrack, switch::Int, measure::Measure)
    pullout_branches!(outgoing_branches(tt, switch), measure)
end

function renamebranch!(tt::TrainTrack, branch::Int, newlabel::Int, measure::Measure)
    renamebranch!(tt, branch, newlabel)
    updatemeasure_renamebranch!(measure, branch, newlabel)
end



function updatemeasure_elementaryop!(tt_afterop::TrainTrack, op::ElementaryTTOperation, last_added_br::Int, measure::Measure)
    if op.optype == PEEL
        updatemeasure_peel!(tt_afterop, measure, op.label1, op.label2)
    elseif op.optype == FOLD
        updatemeasure_fold!(tt_afterop, measure, op.label1, op.label2)
    elseif op.optype == PULLOUT_BRANCHES
        updatemeasure_pullout_branches!(tt_afterop, measure, last_added_br)
    elseif op.optype == COLLAPSE_BRANCH
        updatemeasure_collapse!(measure, op.label1)
    elseif op.optype == RENAME_BRANCH
        updatemeasure_renamebranch!(measure, op.label1, op.label2)
    elseif op.optype == RENAME_SWITCH
    elseif op.optype == DELETE_BRANCH
        updatemeasure_deletebranch!(measure, op.label1)
    else
        @assert false
    end
end


function execute_elementaryops!(tt::TrainTrack, ops, measure::Measure)
    added_sw, added_br = 0, 0
    for op in ops
        added_sw, added_br = execute_elementaryop!(tt, op)
        updatemeasure_elementaryop!(tt, op, added_br, measure) 
    end
    added_sw, added_br
end

function updatemeasure_peel!(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    peel_off_branch = extremal_branch(tt, -switch, otherside(side))
    peeled_branch = next_branch(tt, -peel_off_branch, istwisted(tt, peel_off_branch) ? otherside(side) : side)
    newvalue = branchmeasure(measure, peel_off_branch) - branchmeasure(measure, peeled_branch)
    _setmeasure!(measure, peel_off_branch, newvalue)
end


function updatemeasure_fold!(tt::TrainTrack, measure::Measure, fold_onto_br::Int, folded_br_side::Int)
    sw = branch_endpoint(tt, fold_onto_br)
    folded_br = extremal_branch(tt, -sw, istwisted(tt, fold_onto_br) ? otherside(folded_br_side) : folded_br_side)
    newvalue = branchmeasure(measure, fold_onto_br) + branchmeasure(measure, folded_br)
    _setmeasure!(measure, fold_onto_br, newvalue)
end


function peel!(tt::TrainTrack, switch::Int, side::Int, measure::Measure)
    execute_elementaryops!(tt, (peel_op(switch, side),), measure)
    nothing
end

function fold!(tt::TrainTrack, fold_into_br::Int, folded_br_side::Int, measure::Measure)
    execute_elementaryops!(tt, (fold_op(fold_into_br, folded_br_side),), measure)
    nothing
end

function split_trivalent!(tt::TrainTrack, branch::Int, left_right_or_central::Int, measure::Measure)
    ops = split_trivalent_to_elementaryops(tt, branch, left_right_or_central)
    execute_elementaryops!(tt, ops, measure)
    nothing
end

function fold_trivalent!(tt::TrainTrack, branch::Int, measure::Measure)
    ops = fold_trivalent_to_elementaryops(tt, branch)
    execute_elementaryops!(tt, ops, measure)
    nothing
end

function add_switch_on_branch!(tt::TrainTrack, branch::Int, measure::Measure)
    ops = add_switch_on_branch_to_elementaryops(tt, branch)
    added_sw, added_br = execute_elementaryops!(tt, ops, measure)
    (added_sw, added_br)
end

function delete_two_valent_switch!(tt::TrainTrack, switch::Int, measure::Measure)
    ops = delete_two_valent_switch_to_elementaryops(tt, switch)
    execute_elementaryops!(tt, ops, measure)
    nothing
end

"""
Consider standing at a switch, looking forward. On each side (LEFT, RIGHT), we can peel either the branch going forward or the branch going backward. This function returns FORWARD or BACKWARD, indicating which branch is peeled according to the measure (the one that has smaller measure).

If the measures are equal, then we need to make sure that we are not peeling from the side where there is only one outgoing branch
"""
function whichside_to_peel(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    br1 = extremal_branch(tt, switch, side)
    br2 = extremal_branch(tt, -switch, otherside(side))
    m1 = branchmeasure(measure, br1)
    m2 = branchmeasure(measure, br2)
    if m1 < m2
        return FORWARD
    end
    if m1 > m2
        return BACKWARD
    end

    for sg in (1, -1)
        if remains_recurrent_after_peel(tt, sg*switch, sg == 1 ? side : otherside(side))
            return sg == 1 ? FORWARD : BACKWARD
        end
    end

    @assert false

end


function remains_recurrent_after_peel(tt::TrainTrack, switch::Int, peelside::Int)
    peeledbr = extremal_branch(tt, switch, peelside)
    peeloffbr = extremal_branch(tt, -switch, otherside(peelside))
    backsw = branch_endpoint(tt, peeloffbr)

    switches_visited = [switch]
    current_sw_idx = 1
    while current_sw_idx <= length(switches_visited)
        current_sw = switches_visited[current_sw_idx]
        for br in outgoing_branches(tt, current_sw)
            if current_sw == switch && br == peeledbr
                # We consider the state of the train track after peeling, so we are not allowed to go from switch to peeledbr
                continue
            end
            # After the peeling, the endpoint of -peeledbr changes to backsw
            sw = br != -peeledbr ? -branch_endpoint(tt, br) : -backsw
            if sw == backsw
                # We get back to backsw, which means that we can travel through peeledoffbr to get back to switch. So there is a curve going through backsw and we are good.
                return true
            end
            if !(sw in switches_visited)
                push!(switches_visited, sw)
            end
        end
        current_sw_idx += 1
    end
    return false
end



end
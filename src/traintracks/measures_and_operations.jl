
module MeasuresAndOperations

export collapse_branch!, pull_switch_apart!, delete_two_valent_switch!, add_switch_on_branch!, peel!, fold!, split_trivalent!, fold_trivalent!, renamebranch!, whichside_to_peel

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: _allocatemore!, _setmeasure!
using Donut.TrainTracks: BranchRange
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps
using Donut.TrainTracks.Operations: TTOperationIterator
using Donut.Constants: FORWARD, BACKWARD

function updatemeasure_pullswitchapart!(tt_afterop::TrainTrack,
    measure::Measure, newbranch::Int)
    if newbranch > length(measure.values)
        _allocatemore!(measure, newbranch)
    end
    sw = branch_endpoint(tt_afterop, -newbranch)
    newvalue = outgoingmeasure(tt_afterop, measure, -sw) - outgoingmeasure(tt_afterop, measure, sw)
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

function pull_switch_apart!(tt::TrainTrack,
    front_positions_moved::BranchRange,
    back_positions_stay::BranchRange,
    measure::Measure)
    sw, br = pull_switch_apart!(tt, front_positions_moved, back_positions_stay)
    updatemeasure_pullswitchapart!(tt, measure, br)
end

function renamebranch!(tt::TrainTrack, branch::Int, newlabel::Int, measure::Measure)
    renamebranch!(tt, branch, newlabel)
    updatemeasure_renamebranch!(measure, branch, newlabel)
end

# function execute_elementaryop!(tt::TrainTrack, op::ElementaryTTOperation)
#     last_sw, last_br = 0, 0
#     if op.optype == PULLING
#         last_sw, last_br = pull_switch_apart!(tt, op.front_positions_moved, op.back_positions_stay)
#     elseif op.optype == COLLAPSING
#         collapse_branch!(tt, op.label1)
#     elseif op.optype == RENAME_BRANCH
#         renamebranch!(tt, op.label1, op.label2)
#     elseif op.optype == RENAME_SWITCH
#         renameswitch!(tt, op.label1, op.label2)
#     else
#         @assert false
#     end
#     (last_sw, last_br)
# end


function updatemeasure_elementaryop!(tt_afterop::TrainTrack, op::ElementaryTTOperation, last_added_br::Int, measure::Measure)
    if op.optype == PULLING
        updatemeasure_pullswitchapart!(tt_afterop, measure, last_added_br)
        # need to know the last added branch
    elseif op.optype == COLLAPSING
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

function execute_elementaryops!(tt::TrainTrack, ops::Array{ElementaryTTOperation}, measure::Measure)
    sw, br = 0, 0
    for (tt_afterop, lastop, last_added_sw, last_added_br) in TTOperationIterator(tt, ops)
        sw, br = last_added_sw, last_added_br
        updatemeasure_elementaryop!(tt_afterop, lastop, last_added_br, measure) 
    end
    sw, br
end

function peel!(tt::TrainTrack, switch::Int, side::Int, measure::Measure)
    ops = peeling_to_elementaryops(tt, switch, side)
    execute_elementaryops!(tt, ops, measure)
    nothing
end

function fold!(tt::TrainTrack, switch::Int, side::Int, measure::Measure)
    ops = folding_to_elementaryops(tt, switch, side)
    execute_elementaryops!(tt, ops, measure)
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
"""
function whichside_to_peel(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    br1 = outgoing_branch(tt, switch, 1, side)
    br2 = outgoing_branch(tt, -switch, 1, otherside(side))
    branchmeasure(measure, br1) < branchmeasure(measure, br2) ? FORWARD : BACKWARD
end




end
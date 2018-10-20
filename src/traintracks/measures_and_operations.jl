
module MeasuresAndOperations

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: _allocatemore!, _setmeasure!
using Donut.TrainTracks: BranchRange
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps

function updatemeasure_pullswitchapart!(tt_afterop::TrainTrack,
    measure::Measure, newbranch::Int)
    if newbranch > length(measure.values)
        _allocatemore!(measure, newbranch)
    end
    sw = branch_endpoint(tt_afterop, -newbranch)
    newvalue = outgoingmeasure(tt_afterop, measure, -switch) - outgoingmeasure(tt_afterop, measure, switch)
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


function updatemeasure_elementaryop!(tt_afterop::TrainTrack, op::ElementaryTTOperation, last_added_br::Int)
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


function peel!(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    ops = peeling_to_elementaryops(tt, switch, side)
    for (tt_afterop, lastop, _, last_added_br) in TTOperationIterator(tt, ops)
        updatemeasure_elementaryop!(tt_afterop, lastop, last_added_br) 
    end
end


"""
Consider standing at a switch, looking forward. On each side (LEFT, RIGHT), we can peel either the branch going forward or the branch going backward. This function returns FORWARD or BACKWARD, indicating which branch is peeled according to the measure (the one that has smaller measure).
"""
function whichside_to_peel(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    br1 = outgoing_branch(tt, switch, 1, side)
    br2 = outgoing_branch(tt, -switch, 1, otherside(side))
    branchmeasure(br1) < branchmeasure(br2) ? FORWARD : BACKWARD
end




end
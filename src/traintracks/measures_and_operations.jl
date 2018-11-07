
module MeasuresAndOperations

export collapse_branch!, pull_switch_apart!, delete_two_valent_switch!, add_switch_on_branch!, peel!, fold!, split_trivalent!, fold_trivalent!, renamebranch!, whichside_to_peel

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: _allocatemore!, _setmeasure!
using Donut.TrainTracks: BranchRange
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps
using Donut.TrainTracks.Operations: TTOperationIterator
import Donut.TrainTracks.Operations.peel!
import Donut.TrainTracks.Operations.fold!
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
    peeled_branch = outgoing_branch(tt, switch, 1, side)
    backward_branch = outgoing_branch(tt, -switch, 1, otherside(side))
    newvalue = branchmeasure(measure, backward_branch) - branchmeasure(measure, peeled_branch)
    peel!(tt, switch, side)
    _setmeasure!(measure, backward_branch, newvalue)
end

function fold!(tt::TrainTrack, switch::Int, foldedbr_index::Int, from_side::Int, measure::Measure)
    foldedbranch = outgoing_branch(tt, switch, foldedbr_index, from_side)
    foldonto_branch = outgoing_branch(tt, switch, foldedbr_index+1, from_side)
    newvalue = branchmeasure(measure, foldonto_branch) + branchmeasure(measure, foldedbranch)
    fold!(tt, switch, foldedbr_index, from_side)
    _setmeasure!(measure, foldonto_branch, newvalue)
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
    br1 = outgoing_branch(tt, switch, 1, side)
    br2 = outgoing_branch(tt, -switch, 1, otherside(side))
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

    # When m1 == m2, we have a choice. We need to make sure that after the peeling we get a recurrent train track. In particular, we need to check that locally near the switch, the switch conditions can be satisfied when all the branches have positive measure. For example, this fails when the branches on one side are [7,8,9] and the branches on the other side are [-8]. That is, the branches on one side are a proper subset of the branches on the other side.
    # for sg in (1, -1)
    #     set1 = outgoing_branches(tt, sg*switch, sg == 1 ? side : otherside(side))
    #     if length(set1) == 1
    #         # there is only one branch going forward, so we cannot peel that.
    #         continue
    #     end
    #     set1 = set1[2:length(set1)]
    #     set2 = outgoing_branches(tt, -sg*switch)
    #     backbr = sg == 1 ? br2 : br1
    #     forwbr = sg == 1 ? br1 : br2
    #     if branch_endpoint(tt, backbr) == branch_endpoint(tt, -backbr)
    #         # if the back branch turns back to the back side of the switch, then after the peeling the peeled branch will connect to the opposite side of the switch
    #         set2 = [set2; forwbr]
    #     end
    #     if branch_endpoint(tt, backbr) == -branch_endpoint(tt, -backbr)
    #         # if the back branch turns back to the front side of the switch, then after the peeling the peeled branch will connect to the front side of the switch
    #         set1 = [set1; forwbr]
    #     end
    #     println("Set1:", set1)
    #     println("Set2:", set2)
    #     println("Forwbr:", forwbr)
    #     println("Backbr:", backbr)
    #     if isproper_subset(set1, set2)
    #         # Not recurrent, so this side won't work.
    #         continue
    #     end

    #     # if we got here then our switch is OK.
    #     # Now we have to check if the back switch is OK.
    #     backsw = branch_endpoint(tt, backbr)
    #     println("Backsw: ", backsw)
    #     if abs(switch) != abs(backsw)
    #         backset1 = [outgoing_branches(tt, backsw); forwbr]
    #         backset2 = outgoing_branches(tt, -backsw)
    #         println("BackSet1:", backset1)
    #         println("BackSet2:", backset2)
    #         # println("Forwbr:", forwbr)
    #         # println("Backbr:", backbr)
    #         if isproper_subset(backset2, backset1)
    #             continue
    #         end
    #     end
    #     # If we got here, then the back switch is also OK.
    #     return sg == 1 ? FORWARD : BACKWARD
    # end
    # if we get here then neither side was found good. This shouldn't happen.
    @assert false

    # if numoutgoing_branches(tt, switch) > 1
    #     return FORWARD
    # elseif numoutgoing_branches(tt, -switch) > 1
    #     return BACKWARD
    # else
    #     error("Switch $(switch) is two-valent. We cannot peel either side.")
    # end
end


function remains_recurrent_after_peel(tt::TrainTrack, switch::Int, peelside::Int)
    peeledbr = outgoing_branch(tt, switch, 1, peelside)
    peeloffbr = outgoing_branch(tt, -switch, 1, otherside(peelside))
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

# function isproper_subset(set1::AbstractArray{Int, 1}, set2::AbstractArray{Int, 1})
#     for br in set1
#         if !(-br in set2)
#             # set1 is not a subset of set2, so this side is good.
#             return false
#         end
#     end
#     # if we got here, then set1 is a subset of set2. If not a proper subset, we are still good.
#     if length(set1) == length(set2)
#         return false
#     end
#     return true
# end

end
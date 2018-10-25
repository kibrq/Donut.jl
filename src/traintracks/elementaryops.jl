

module ElementaryOps

export ElementaryTTOperation, pulling_op, collapsing_op, renaming_branch_op, renaming_switch_op, delete_branch_op, delete_two_valent_switch_to_elementaryops, add_switch_on_branch_to_elementaryops, peeling_to_elementaryops, folding_to_elementaryops, split_trivalent_to_elementaryops, fold_trivalent_to_elementaryops, PULLING, COLLAPSING, RENAME_BRANCH, RENAME_SWITCH, DELETE_BRANCH

using Donut.TrainTracks
using Donut.TrainTracks: BranchRange
using Donut.Utils: otherside
using Donut.Constants: LEFT, RIGHT, CENTRAL


const PULLING = 0
const COLLAPSING = 1
const RENAME_BRANCH = 2
const RENAME_SWITCH = 3
const DELETE_BRANCH = 4

struct ElementaryTTOperation
    optype::Int
    label1::Int
    label2::Int
    front_positions_moved::BranchRange
    back_positions_stay::BranchRange    
end

pulling_op(front_positions_moved::BranchRange, back_positions_stay::BranchRange) = ElementaryTTOperation(PULLING, 0, 0, front_positions_moved, back_positions_stay)

collapsing_op(collapsedbranch::Int) = ElementaryTTOperation(COLLAPSING, collapsedbranch, 0, BranchRange(), BranchRange())

renaming_branch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_BRANCH, oldlabel, newlabel, BranchRange(), BranchRange())

renaming_switch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_SWITCH, oldlabel, newlabel, BranchRange(), BranchRange())

delete_branch_op(label::Int) = ElementaryTTOperation(DELETE_BRANCH, label, 0, BranchRange(), BranchRange())




# ------------------------------------
# Composite Operations
# ------------------------------------


"""
Delete a two-valent switch.

The branch behind the switch is collapsed.
If the switch is not two-valent, an error is thrown.

"""
function delete_two_valent_switch_to_elementaryops(tt::TrainTrack, switch::Int)
    @assert switchvalence(tt, switch) == 2
    br_removed = outgoing_branch(tt, -switch, 1)
    return [collapsing_op(-br_removed)]
end



"""
Create a switch on a branch.

The orientation of the new switch is the same as the orientation of the branch. The new branch is
added before the switch. The new branch is always untwisted.

RETURN: (new_switch, new_branch)
"""
function add_switch_on_branch_to_elementaryops(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    index = outgoing_branch_index(tt, start_sw, branch)
    front_moved = BranchRange(start_sw, index:index)
    back_stayed = BranchRange(-start_sw, 1:numoutgoing_branches(tt, -start_sw))
    op = pulling_op(front_moved, back_stayed)
    [op]
end

"""
We stand at switch, looking forward, take the left-most or the right-most branch and peel it off the branch emanating from the switch backwards.
"""
function peeling_to_elementaryops(tt::TrainTrack, switch::Int, side::Int)
    if numoutgoing_branches(tt, switch) == 1
        error("Peeling at switch $(switch) is not possible, since there is only one outgoing branch")
    end
    front_positions_moved = BranchRange(-switch, 1:1, otherside(side))
    num = numoutgoing_branches(tt, switch)
    back_positions_stay = BranchRange(switch, 2:num, side)
    op1 = pulling_op(front_positions_moved, back_positions_stay)

    collapsedbranch = outgoing_branch(tt, -switch, 1, otherside(side))
    op2 = collapsing_op(-collapsedbranch)  # negate so the newly added switch gets salvaged.

    op3 = renaming_branch_op(0, collapsedbranch)
    [op1, op2, op3]
end

"""
We stand at switch, looking forward and consider either the left of the right side of the switch. We consider the extremal backward branch on that side, find its other endpoint (back_sw) and fold the branch that is neighboring at back_sw onto our backward branch. (This is the inverse of peeling.)
"""   
# TODO if branches are twisted, this function may not be correct
function folding_to_elementaryops(tt::TrainTrack, switch::Int, side::Int)
    back_br = outgoing_branch(tt, -switch, 1, otherside(side))
    back_sw = branch_endpoint(tt, back_br)
    back_side = istwisted(tt, back_br) ? otherside(side) : side
    index = outgoing_branch_index(tt, back_sw, -back_br, back_side)
    # println(switch, side, back_br, back_sw, back_side, index)
    if index == 1
        error("Folding on the $(side==LEFT ? "left" : "right") side of switch $(switch) is not possible.")
    end
    folded_br = outgoing_branch(tt, back_sw, index-1, back_side)
    front_moved = BranchRange(back_sw, index-1:index, back_side)
    back_stayed = BranchRange(-back_sw, 1:numoutgoing_branches(tt, -back_sw))
    op1 = pulling_op(front_moved, back_stayed)
    op2 = collapsing_op(back_br)
    op3 = renaming_branch_op(0, -back_br)
    [op1, op2, op3]
end


"""
Left split: central branch is turning left after the splitting.

TODO: we could write this in terms of two peels with safer code, but we would get more elementary operations that way.
"""
function split_trivalent_to_elementaryops(tt::TrainTrack, branch::Int, left_right_or_central::Int)
    if !is_branch_large(tt, branch)
        error("The split branch should be a large branch.")
    end
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    if switchvalence(tt, start_sw) != 3 && switchvalence(tt, end_sw) != 3
        error("The endpoints of the split branch should be trivalent.")
    end
    @assert left_right_or_central in (LEFT, RIGHT, CENTRAL)

    ops = ElementaryTTOperation[]
    push!(ops, collapsing_op(branch))  # end_sw and branch are deleted
    side = left_right_or_central == CENTRAL ? LEFT : left_right_or_central
    push!(ops, pulling_op(BranchRange(start_sw, 1:1, side), BranchRange(-start_sw, 1:1, side)))  # creates new_br (same direction as branch) and new_sw (opposite direction of end_sw)
    push!(ops, renaming_branch_op(0, branch))  # 0 is the placeholder for new_br
    push!(ops, renaming_switch_op(0, -end_sw))  # 0 is the placeholder to new_sw

    if left_right_or_central == CENTRAL
        push!(ops, delete_branch_op(0))  # 0 is the placeholder for new_br
        back_br = outgoing_branch(tt, -start_sw, 1, LEFT)
        push!(ops, collapsing_op(-back_br))
        front_br = outgoing_branch(tt, -end_sw, 1, istwisted(tt, branch) ? LEFT : RIGHT)
        push!(ops, collapsing_op(-front_br))
        # TODO: What do we do when this would remove the last switch of the train track?
    end

    ops
end

"""
TODO: we could write this in terms of two folds with safer code, but we would get more elementary operations that way.
"""
function fold_trivalent_to_elementaryops(tt::TrainTrack, branch::Int)
    if !is_branch_small_foldable(tt, branch)
        error("Branch $(branch) is not small foldable.")
    end
    end_sw = branch_endpoint(tt, branch)
    start_sw = branch_endpoint(tt, -branch)
    op1 = collapsing_op(branch)

    front_moved = BranchRange(start_sw, 1:2, LEFT)
    back_stayed = BranchRange(-start_sw, 1:2, LEFT)
    op2 = pulling_op(front_moved, back_stayed)

    op3 = renaming_branch_op(0, branch)
    op4 = renaming_switch_op(0, -end_sw)
    [op1, op2, op3, op4]
end

    



end


module ElementaryOps

export ElementaryTTOperation, pulling_op, collapsing_op, renaming_branch_op, renaming_switch_op, delete_branch_op, delete_two_valent_switch_to_elementaryops, add_switch_on_branch_to_elementaryops, peeling_to_elementaryops, folding_to_elementaryops, split_trivalent_to_elementaryops, fold_trivalent_to_elementaryops, PEEL, FOLD, PULLOUT_BRANCHES, COLLAPSE_BRANCH, RENAME_BRANCH, RENAME_SWITCH

using Donut.TrainTracks
using Donut.TrainTracks: BranchIterator
using Donut.Utils: otherside
using Donut.Constants: LEFT, RIGHT, CENTRAL

const PEEL = 0
const FOLD = 1
const PULLOUT_BRANCHES = 2
const COLLAPSE_BRANCH = 3
const RENAME_BRANCH = 4
const RENAME_SWITCH = 5

struct ElementaryTTOperation
    optype::Int
    label1::Int
    label2::Int
    label3::Int
end

ElementaryTTOperation(a, b) = ElementaryTTOperation(a, b, 0, 0)
ElementaryTTOperation(a, b, c) = ElementaryTTOperation(a, b, c, 0)


peel_op(switch::Int, side::Int) = ElementaryTTOperation(PEEL, switch, side)

fold_op(fold_onto_br::Int, folded_br_side::Int) = ElementaryTTOperation(FOLD, fold_onto_br, folded_br_side)

# pull_switch_op(switch::Int) = ElementaryTTOperation(PULL_SWITCH, switch)
pullout_branches_op(start_br::Int, end_br::Int, start_side::Int=LEFT) = ElementaryTTOperation(PULLOUT_BRANCHES, start_br, end_br, start_side)

collapse_branch_op(branch::Int) = ElementaryTTOperation(COLLAPSE_BRANCH, branch)

renaming_branch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_BRANCH, oldlabel, newlabel)

renaming_switch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_SWITCH, oldlabel, newlabel)




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
    br_removed = extremal_branch(tt, -switch, LEFT)
    # br_removed = outgoing_branch(tt, -switch, 1)
    return (collapse_branch_op(-br_removed),)
end



"""
Create a switch on a branch.

The orientation of the new switch is the same as the orientation of the branch. The new branch is
added before the switch. The new branch is always untwisted.

RETURN: (new_switch, new_branch)
"""
function add_switch_on_branch_to_elementaryops(tt::TrainTrack, branch::Int)
    return (pullout_branches_op(branch, branch),)
end

# """
# We stand at switch, looking forward, take the left-most or the right-most branch and peel it off the branch emanating from the switch backwards.
# """
# function peeling_to_elementaryops(tt::TrainTrack, switch::Int, side::Int)
#     if numoutgoing_branches(tt, switch) == 1
#         error("Peeling at switch $(switch) is not possible, since there is only one outgoing branch")
#     end
#     front_positions_moved = BranchRange(-switch, 1:1, otherside(side))
#     num = numoutgoing_branches(tt, switch)
#     back_positions_stay = BranchRange(switch, 2:num, side)
#     op1 = pulling_op(front_positions_moved, back_positions_stay)

#     collapsedbranch = outgoing_branch(tt, -switch, 1, otherside(side))
#     op2 = collapsing_op(-collapsedbranch)  # negate so the newly added switch gets salvaged.

#     op3 = renaming_branch_op(0, collapsedbranch)
#     [op1, op2, op3]
# end

# """
# We stand at switch, looking forward and consider either the left of the right side of the switch. We consider the extremal backward branch on that side, find its other endpoint (back_sw) and fold the branch that is neighboring at back_sw onto our backward branch. (This is the inverse of peeling.)
# """   
# # TODO if branches are twisted, this function may not be correct
# function folding_to_elementaryops(tt::TrainTrack, switch::Int, side::Int)
#     back_br = outgoing_branch(tt, -switch, 1, otherside(side))
#     back_sw = branch_endpoint(tt, back_br)
#     back_side = istwisted(tt, back_br) ? otherside(side) : side
#     index = outgoing_branch_index(tt, back_sw, -back_br, back_side)
#     # println(switch, side, back_br, back_sw, back_side, index)
#     if index == 1
#         error("Folding on the $(side==LEFT ? "left" : "right") side of switch $(switch) is not possible.")
#     end
#     folded_br = outgoing_branch(tt, back_sw, index-1, back_side)
#     front_moved = BranchRange(back_sw, index-1:index, back_side)
#     back_stayed = BranchRange(-back_sw, 1:numoutgoing_branches(tt, -back_sw))
#     op1 = pulling_op(front_moved, back_stayed)
#     op2 = collapsing_op(back_br)
#     op3 = renaming_branch_op(0, -back_br)
#     [op1, op2, op3]
# end


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
    side = left_right_or_central == CENTRAL ? LEFT : left_right_or_central

    return (
        peel_op(-start_sw, otherside(side)),
        peel_op(-end_sw, istwisted(tt, branch) ? side : otherside(side))
    )
end


function fold_trivalent_to_elementaryops(tt::TrainTrack, branch::Int)
    # if !is_branch_small_foldable(tt, branch)
    #     error("Branch $(branch) is not small foldable.")
    # end
    fold_side = -100
    for side in (LEFT, RIGHT)
        is_side_good = true
        for sgn in (1, -1)
            br1 = next_branch(tt, sgn*branch, side)
            if br1 != 0
                is_side_good = false
                break
            end
            br2 = next_branch(tt, branch, otherside(side))
            if br2 == 0
                is_side_good = false
                break
            end
            br3 = next_branch(tt, br2, otherside(side))
            if br3 != 0
                is_side_good = false
                break
            end
        end
        if !is_side_good
            continue
        else
            fold_side = otherside(side)
            break
        end
    end
    if fold_side == -100
        error("Branch $(branch) is not small foldable.")
    end

    return (
        fold_op(branch, fold_side),
        fold_op(-branch, fold_side)
    )
end

    



end
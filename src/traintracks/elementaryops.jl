

module ElementaryOps

export ElementaryTTOperation, pulling_op, collapsing_op, renaming_branch_op, 
    renaming_switch_op, delete_branch_op, delete_two_valent_switch_to_elementaryops, 
    add_switch_on_branch_to_elementaryops, peel_op, fold_op, split_trivalent_to_elementaryops, 
    fold_trivalent_to_elementaryops, PEEL, FOLD, PULLOUT_BRANCHES, COLLAPSE_BRANCH, 
    RENAME_BRANCH, RENAME_SWITCH, TTOperationType, TrivalentSplitType, LEFT_SPLIT, 
    RIGHT_SPLIT, CENTRAL_SPLIT

using Donut.TrainTracks
using Donut.TrainTracks: BranchIterator
using Donut.Constants: CENTRAL
using Donut.Constants

@enum TTOperationType PEEL FOLD PULLOUT_BRANCHES COLLAPSE_BRANCH RENAME_BRANCH RENAME_SWITCH

struct ElementaryTTOperation
    optype::TTOperationType
    label1::Int
    label2::Int
    side::Side
end

@enum TrivalentSplitType LEFT_SPLIT RIGHT_SPLIT CENTRAL_SPLIT

# ElementaryTTOperation(a, b) = ElementaryTTOperation(a, b, 0, 0)
# ElementaryTTOperation(a, b, c) = ElementaryTTOperation(a, b, c, 0)


peel_op(switch::Int, side::Side) = ElementaryTTOperation(PEEL, switch, 0, side)

fold_op(fold_onto_br::Int, folded_br_side::Side) = ElementaryTTOperation(FOLD, fold_onto_br, 0, folded_br_side)

# pull_switch_op(switch::Int) = ElementaryTTOperation(PULL_SWITCH, switch)
pullout_branches_op(start_br::Int, end_br::Int, start_side::Side=LEFT) = 
    ElementaryTTOperation(PULLOUT_BRANCHES, start_br, end_br, start_side)

collapse_branch_op(branch::Int) = ElementaryTTOperation(COLLAPSE_BRANCH, branch, 0, LEFT)

renaming_branch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_BRANCH, oldlabel, newlabel, LEFT)

renaming_switch_op(oldlabel::Int, newlabel::Int) = ElementaryTTOperation(RENAME_SWITCH, oldlabel, newlabel, LEFT)




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


"""
Left split: central branch is turning left after the splitting.

TODO: we could write this in terms of two peels with safer code, but we would get more elementary operations that way.
"""
function split_trivalent_to_elementaryops(tt::TrainTrack, branch::Int, 
    left_right_or_central::TrivalentSplitType)
    if !is_branch_large(tt, branch)
        error("The split branch should be a large branch.")
    end
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    if switchvalence(tt, start_sw) != 3 && switchvalence(tt, end_sw) != 3
        error("The endpoints of the split branch should be trivalent.")
    end

    side = left_right_or_central == RIGHT_SPLIT ? RIGHT : LEFT

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
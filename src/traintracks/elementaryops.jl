


export ElementaryTTOperation, TTOperation, Peel, Fold, PulloutBranches, 
    CollapseBranch, RenameBranch, RenameSwitch, ReverseBranch, ReverseSwitch,
    DeleteBranch, DeleteTwoValentSwitch, AddSwitchOnBranch,
    SplitTrivalent, FoldTrivalent, TrivalentSplitType, LEFT_SPLIT, 
    RIGHT_SPLIT, CENTRAL_SPLIT, convert_to_elementaryops


abstract type TTOperation end
abstract type ElementaryTTOperation <: TTOperation end

struct Peel <: ElementaryTTOperation
    sw::Int16
    side::Side
end

struct Fold <: ElementaryTTOperation
    fold_onto_br::Int16
    folded_br_side::Side
end

struct PulloutBranches <: ElementaryTTOperation
    start_br::Int16
    end_br::Int16
    start_side::Side
end

PulloutBranches(a, b) = PulloutBranches(a, b, LEFT)

struct CollapseBranch <: ElementaryTTOperation
    br::Int16
end

struct RenameBranch <: ElementaryTTOperation
    oldlabel::Int16
    newlabel::Int16
end

struct RenameSwitch <: ElementaryTTOperation
    oldlabel::Int16
    newlabel::Int16
end    

struct DeleteBranch <: ElementaryTTOperation
    br::Int16
end







# ------------------------------------
# Composite Operations
# ------------------------------------

"""
Delete a two-valent switch.

The branch behind the switch is collapsed.
If the switch is not two-valent, an error is thrown.

"""
struct DeleteTwoValentSwitch <: TTOperation
    sw::Int16
end

function convert_to_elementaryops(tt::TrainTrack, op::DeleteTwoValentSwitch)
    @assert switchvalence(tt, op.sw) == 2
    br_removed = extremal_branch(tt, -op.sw, LEFT)
    return (CollapseBranch(-br_removed),)
end


"""
Create a switch on a branch.

The orientation of the new switch is the same as the orientation of the branch. The new branch is
added before the switch. The new branch is always untwisted.
"""
struct AddSwitchOnBranch <: TTOperation
    br::Int16
end

function convert_to_elementaryops(tt::TrainTrack, op::AddSwitchOnBranch)
    return (PulloutBranches(op.br, op.br),)
end


@enum TrivalentSplitType::Int8 LEFT_SPLIT RIGHT_SPLIT CENTRAL_SPLIT


"""
Left split: central branch is turning left after the splitting.
"""
struct SplitTrivalent <: TTOperation
    br::Int16
    split_type::TrivalentSplitType
end

function convert_to_elementaryops(tt::TrainTrack, op::SplitTrivalent)
    if !is_branch_large(tt, op.br)
        error("The split branch should be a large branch.")
    end
    start_sw = branch_endpoint(tt, -op.br)
    end_sw = branch_endpoint(tt, op.br)
    if switchvalence(tt, start_sw) != 3 && switchvalence(tt, end_sw) != 3
        error("The endpoints of the split branch should be trivalent.")
    end

    side = op.split_type == RIGHT_SPLIT ? RIGHT : LEFT

    return (
        Peel(-start_sw, otherside(side)),
        Peel(-end_sw, istwisted(tt, op.br) ? side : otherside(side))
    )
end


struct FoldTrivalent <: TTOperation
    br::Int16
end

function convert_to_elementaryops(tt::TrainTrack, op::FoldTrivalent)
    # if !is_branch_small_foldable(tt, branch)
    #     error("Branch $(branch) is not small foldable.")
    # end
    fold_side = -100
    for side in (LEFT, RIGHT)
        is_side_good = true
        for sgn in (1, -1)
            br1 = next_branch(tt, sgn*op.br, side)
            if br1 != 0
                is_side_good = false
                break
            end
            br2 = next_branch(tt, op.br, otherside(side))
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
        error("Branch $(op.br) is not small foldable.")
    end

    return (
        Fold(op.br, fold_side),
        Fold(-op.br, fold_side)
    )
end

    
struct ReverseSwitch <: TTOperation
    sw::Int16
end

function convert_to_elementaryops(tt::TrainTrack, op::ReverseSwitch)
    (RenameSwitch(op.sw, -op.sw),)
end


struct ReverseBranch <: TTOperation
    br::Int16
end

function convert_to_elementaryops(tt::TrainTrack, op::ReverseBranch)
    (RenameBranch(op.br, -op.br),)
end





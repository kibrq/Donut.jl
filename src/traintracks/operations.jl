
module Operations

export collapse_branch!, pull_switch_apart!, delete_branch!, delete_two_valent_switch!, peel!, add_switch_on_branch!, twist_branch!, add_branch!


using Donut.TrainTracks
using Donut.TrainTracks: _setend!
using Donut
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD, START, END
using Donut.Utilities: otherside

_setendpoint!(tt::TrainTrack, branch::Int, switch::Int) =
    _setend!(branch, switch, tt.branches)


_set_numoutgoing_branches!(tt::TrainTrack, switch::Int, number::Int) =
    tt.switches[abs(switch)].numoutgoing_branches[switch > 0 ? FORWARD : BACKWARD] = number


struct BranchPosition
    switch::Int
    index::Int
    start_side::Int
end

BranchPosition(sw, idx) = BranchPosition(sw, idx, LEFT)

struct BranchRange
    switch::Int
    index_range::UnitRange{Int}
    start_side::Int
end

BranchRange(sw, index_range) = BranchRange(sw, index_range, LEFT)




"""
Inserts some outgoing branches to the specified switch a the specified position.

Only the branch indices are inserted.

WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
function _splice_outgoing_branches!(tt::TrainTrack,
                                    insert_range::BranchRange,
                                    inserted_branches = AbstractArray{Int, 1})

    # WARNING: This shouldn't use branch_endpoint, since that could break the reglue branches function.

    switch = insert_range.switch
    index_range = insert_range.index_range
    start_side = insert_range.start_side

    num_br = numoutgoing_branches(tt, switch)
    arr_view = outgoing_branches(tt, switch)

    try
        arr_view[index_range]
    catch ex
        if isa(y, BoundsError)
            error("Range $(index_range) is invalid for the outgoing branches at switch $(switch).")
        else
            error("Unexpected error.")
        end
    end

    direction = switch > 0 ? FORWARD : BACKWARD
    full_arr = tt.switches[abs(switch)].outgoing_branch_indices[direction]


    if start_side == RIGHT
        index_range = (num_br - index_range.stop + 1) : (num_br - index_range.start + 1)
        inserted_branches = inserted_branches[end:-1:1]
    end
    splice!(full_arr, index_range, inserted_branches)

    num_added_branches = length(inserted_branches)
    num_deleted_branches = index_range.stop - index_range.start + 1
    new_total = num_br + num_added_branches - num_deleted_branches
    _set_numoutgoing_branches!(tt, switch, new_total)
end




"""
WARNING: It leaves the TrainTrack object in an inconsistent state!
"""
function _insert_outgoing_branches!(tt::TrainTrack,
                                    insert_pos::BranchPosition,
                                    inserted_branches = AbstractArray{Int, 1})
    range = BranchRange(insert_pos.switch,
                                insert_pos.index+1:insert_pos.index,
                                insert_pos.start_side)
    _splice_outgoing_branches!(tt, range, inserted_branches)
end




"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
function _delete_outgoing_branches!(tt::TrainTrack,
                                    delete_range::BranchRange)
    _splice_outgoing_branches!(tt, delete_range, Int[])
end




"""
Reglue a range of branches from one switch to another.

It updates both the the outgoing branches of switches and endpoints of branches.
"""
function _reglue_outgoing_branches!(
    tt::TrainTrack,
    from_range::BranchRange,
    to_position::BranchPosition)

    start = from_range.index_range.start
    stop = from_range.index_range.stop
    delete_range = start:stop

    if from_range.switch == to_position.switch
        if from_range.start_side == to_position.start_side
            smallest_bad_pos = start
            largest_bad_pos = stop-1
        else
            n = numoutgoing_branches(tt, from_range.switch)
            smallest_bad_pos = n-stop+1
            largest_bad_pos = n-start
        end

        len = stop-start+1:stop
        if to_position.index < smallest_bad_pos
            delete_range = start+len:stop+len
        elseif smallest_bad_pos <= to_position.index <= largest_bad_pos
            error("Cannot insert the branches from where they are being deleted.")
        end

    end

    for idx in from_range.index_range
        br = outgoing_branch(tt, from_range.switch, idx, from_range.start_side)
        _setendpoint!(tt, -br, to_position.switch)
    end

    inserted_branches = view(outgoing_branches(tt, from_range.switch, from_range.start_side), from_range.index_range)
    _insert_outgoing_branches!(tt, to_position, inserted_branches)
    fixed_range = BranchRange(from_range.switch, delete_range, from_range.start_side)
    _delete_outgoing_branches!(tt, fixed_range)
end


twist_branch!(tt::TrainTrack, branch::Int) = (tt.branches[abs(branch)].istwisted = !tt.branches[abs(branch)].istwisted)


"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
_delete_branch!(tt::TrainTrack, branch::Int) = (tt.branches[abs(branch)] = Donut.TrainTracks.Branch())


"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
_delete_switch!(tt::TrainTrack, switch::Int) = (tt.switches[abs(switch)] = Donut.TrainTracks.Switch())



function delete_branch!(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)

    for sw in (start_sw, end_sw)
        if numoutgoing_branches(tt, sw) == 1
            error("Branch $(branch) cannot be deleted, one of its endpoints has only one outgoing branches.")
        end
    end
    start_pos = outgoing_branch_index(tt, start_sw, branch)
    _delete_outgoing_branches!(tt, BranchRange(start_sw, start_pos:start_pos))
    end_pos = outgoing_branch_index(tt, end_sw, -branch)
    _delete_outgoing_branches!(tt, BranchRange(end_sw, end_pos:end_pos))
    _delete_branch!(tt, branch)
end


"""
Collapse a branch if possible.

Collapsing a branch `b` is not possible if and only if either the left or right side of `b` has
branches emanating towards `b` from both the ending and the starting point of `b`.

After the collapse, the two endpoints of `b` merge together and, as a result, one switch is removed.

Return: switch_removed::Int in absolute value.

"""
function collapse_branch!(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    switch_removed = end_sw

    if abs(start_sw) == abs(end_sw)
        error("A branch connecting a switch to itself is not collapsible.")
    end

    if istwisted(tt, branch)
        end_left = RIGHT
        end_right = LEFT
    else
        end_left = LEFT
        end_right = RIGHT
    end

    positions = ((outgoing_branch_index(tt, start_sw, branch, LEFT),
                  outgoing_branch_index(tt, start_sw, branch, RIGHT)),
                 (outgoing_branch_index(tt, end_sw, -branch, end_left),
                  outgoing_branch_index(tt, end_sw, -branch, end_right)))

    left_side_fails = positions[START][LEFT] > 1 && positions[END][RIGHT] > 1
    right_side_fails = positions[START][RIGHT] > 1 && positions[END][LEFT] > 1

    if left_side_fails || right_side_fails
        error("The specified branch is not collapsible: there are branches that block the collapse.")
    end

    from_range = BranchRange(end_sw, 1:positions[END][LEFT]-1, end_left)
    to_position = BranchPosition(-start_sw, 0, LEFT)
    _reglue_outgoing_branches!(tt, from_range, to_position)

    from_range = BranchRange(end_sw, 1:positions[END][RIGHT]-1, end_right)
    to_position = BranchPosition(-start_sw, 0, RIGHT)
    _reglue_outgoing_branches!(tt, from_range, to_position)

    insert_pos = outgoing_branch_index(tt, start_sw, branch)
    _delete_outgoing_branches!(tt, BranchRange(start_sw, insert_pos:insert_pos))
    if istwisted(tt, branch)
        for br in outgoing_branches(tt, -end_sw)
            twist_branch!(tt, br)
        end
    end

    _reglue_outgoing_branches!(
        tt,
        BranchRange(-end_sw, 1:numoutgoing_branches(tt, -end_sw), end_left),
        BranchPosition(start_sw, insert_pos-1))

    _delete_branch!(tt, branch)
    _delete_switch!(tt, end_sw)

    return abs(switch_removed)
end



"""
Delete a two-valent switch.

If the switch is not two-valent, an error is thrown.

Return: (br_kept, br_removed) -- the branch kept and the branched removed
"""
function delete_two_valent_switch!(tt::TrainTrack, switch::Int)
    @assert switch_valence(tt, switch) == 2

    br_removed = outgoing_branch(tt, switch, 1)
    br_kept = outgoing_branch(tt, -switch, 1)
    collapse_branch!(tt, -br_removed)
    return (abs(br_kept), abs(br_removed))
end



""" Return a switch number with is suitable as a new switch.

The new switch won't be connected to any branches just yet.
If necessary, new space is allocated.
"""
function _find_new_switch_number!(tt::TrainTrack)
    for i in eachindex(tt.switches)
        if !isswitch(tt, i)
            return i
        end
    end
    push!(tt.switches, Donut.TrainTracks.Switch())
    return length(tt.switches)
end

"""
Return a positive integer suitable for an additional branch.

The new branch won't be connected to any switches just yet. If
necessary, new space is allocated.
"""
function _find_new_branch_number!(tt::TrainTrack)
    for i in eachindex(tt.branches)
        if !isbranch(tt, i)
            return i
        end
    end
    push!(tt.branches, Donut.TrainTracks.Branch())
    return length(tt.branches)
end





"""
Create a new branch with the specified start and end switches.

In case ``start_switch`` equals ``end_switch``, keep in mind for
specifying indices that the start is inserted first, and the end
second. So if ``start_idx == 0`` and ``end_idx == 0``, then the end
will be to the left of start. If ``end_idx == 1`` instead, then the end
will be on the right of start.
"""
function add_branch!(tt::TrainTrack, start_branch_pos::BranchPosition,
                     end_branch_pos::BranchPosition, istwisted=false)
    br = _find_new_branch_number!(tt)

    _insert_outgoing_branches!(tt, start_branch_pos, [br])
    _insert_outgoing_branches!(tt, end_branch_pos, [-br])
    _setendpoint!(tt, br, end_branch_pos.switch)
    _setendpoint!(tt, -br, start_branch_pos.switch)
    if istwisted
        twist_branch!(tt, br)
    end
    return br
end


"""
Create a switch on a branch.

The orientation of the new switch is the same as the orientation of the branch. The new branch is
added after the switch. The new branch is always untwisted.

RETURN: (new_switch, new_branch)
"""
function add_switch_on_branch!(tt::TrainTrack, branch::Int)
    end_sw = branch_endpoint(tt, branch)
    end_index = outgoing_branch_index(tt, end_sw, -branch)

    new_sw = _find_new_switch_number!(tt)

    _reglue_outgoing_branches!(tt,
                               BranchRange(end_sw, end_index:end_index),
                               BranchPosition(-new_sw, 0))

    new_br = add_branch!(tt, BranchPosition(new_sw, 0),
                         BranchPosition(end_sw, end_index-1))
    (new_sw, new_br)
end



"""
Inverse of collapsing a branch.

RETURN: (new_switch, new_branch)
"""
function pull_switch_apart!(tt::TrainTrack,
                           front_positions_moved::BranchRange,
                           back_positions_stay::BranchRange)
    if front_positions_moved.switch != -back_positions_stay.switch
        error("The switches in the two BranchRanges should be negatives of each other.")
    end

    # front and back ranges cannot be empty
    for rang in (front_positions_moved.index_range,
                 back_positions_stay.index_range)
        if rang.start > rang.stop
            error("At least one branch has to move on the front side and stay on the back side.")
        end
    end

    sw = front_positions_moved.switch
    new_sw = _find_new_switch_number!(tt)

    _reglue_outgoing_branches!(
        tt, front_positions_moved,
        BranchPosition(new_sw, 0, front_positions_moved.start_side))

    r = back_positions_stay.index_range
    back_side = back_positions_stay.start_side
    back_positions_moved1 = BranchRange(-sw, 1:r.start-1, back_side)
    back_positions_moved2 = BranchRange(-sw, r.stop+1:numoutgoing_branches(tt, -sw), back_side)

    _reglue_outgoing_branches!(
        tt, back_positions_moved2, BranchPosition(-new_sw, 0, back_side))

    _reglue_outgoing_branches!(
        tt, back_positions_moved1, BranchPosition(-new_sw, 0, back_side))

    front_side = front_positions_moved.start_side

    new_br = add_branch!(
        tt,
        BranchPosition(sw, front_positions_moved.index_range.start-1, front_side),
        BranchPosition(-new_sw, back_positions_stay.index_range.start-1, back_side)
    )

    (new_sw, new_br)
end


# """

# The old switch number is inherited by the "tip" of the split, that is, the resulting 3-valent
# switch. The three resulting switches are oriented in the same way as the original switch. The two
# new branches are oriented in the same direction as the switches

# Return: (sw_left, sw_right, br_left, br_right) -- the two new switch numbers, to the left and right
# of the split, and the two new branch numbers, to the left and right of the split.
# """
# function split_slightly!(tt::TrainTrack,
#                          split_cusp_pos::BranchPosition,
#                          split_branch_pos::BranchPosition)

# end



# TODO: Shall we do peeling also using collapsing and pulling apart? In that case, we need to renumber a branch.
function peel!(tt::TrainTrack, switch::Int, side::Int)
    if numoutgoing_branches(tt, switch) == 1
        error("Cannot peel at $(switch), because there is only one branch going forward.")
    end

    peeled_branch = outgoing_branch(tt, 1, side)
    backward_branch = outgoing_branch(tt, -switch, otherside(side))
    back_sw = branch_endpoint(tt, backward_branch)
    back_side = !istwisted(tt, backward_branch) ? side : otherside(side)
    pos = outgoing_branch_index(tt, back_sw, -backward_branch, side)
    _reglue_outgoing_branches!(tt,
                               BranchRange(switch, 1:1, side),
                               BranchPosition(back_sw, pos-1, side))
    if istwisted(tt, backward_branch)
        twist!(tt, peeled_branch)
    end
end





end
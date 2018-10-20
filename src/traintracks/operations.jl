
module Operations

export twist_branch!, renamebranch!, reversebranch!, reverseswitch!, renameswitch!, add_branch!, delete_branch!, collapse_branch!, pull_switch_apart!, add_switch_on_branch!, delete_two_valent_switch!, peel!, fold!, split_trivalent!, fold_trivalent!


using Donut.TrainTracks
using Donut.TrainTracks: _setend!, Branch, Switch, copy, zeroout, BranchPosition, BranchRange
using Donut
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD, START, END
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps

# ------------------------------------
# Utility methods
# ------------------------------------


"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
_setendpoint!(tt::TrainTrack, branch::Int, switch::Int) =
    _setend!(branch, switch, tt.branches)

"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
_set_numoutgoing_branches!(tt::TrainTrack, switch::Int, number::Int) =
    tt.switches[abs(switch)].numoutgoing_branches[switch > 0 ? FORWARD : BACKWARD] = number

function _setoutgoing_branch!(tt::TrainTrack, 
    pos::BranchPosition, newvalue::Int)
    _splice_outgoing_branches!(tt, 
        BranchRange(pos.switch, pos.index:pos.index, pos.start_side), [newvalue])
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




# ------------------------------------
# Renaming switches, branches
# ------------------------------------

function renamebranch!(tt::TrainTrack, branch::Int, newlabel::Int)
    @assert 1 <= abs(newlabel) <= length(tt.branches)
    @assert !isbranch(tt, newlabel) || abs(newlabel) == abs(branch)

    # When the starting and ending points are the same, we don't want to make changes twice.
    orbranches = branch_endpoint(tt, branch) == branch_endpoint(tt, -branch) ? (branch) : (branch, -branch)
    for orbranch in orbranches
        sw = branch_endpoint(tt, orbranch)
        for i in 1:numoutgoing_branches(tt, sw)
            br = outgoing_branch(tt, sw, i)
            if abs(br) == abs(branch)
                _setoutgoing_branch!(tt, BranchPosition(sw, i), sign(br)*newlabel)
            end
        end
    end
    if abs(branch) != abs(newlabel)
        copy(tt.branches[abs(branch)], tt.branches[abs(newlabel)])
        zeroout(tt.branches[abs(branch)])
    end
    if sign(branch) != sign(newlabel)
        ends = tt.branches[abs(newlabel)].endpoint
        ends[START], ends[END] = ends[END], ends[START]
    end
end


function reversebranch!(tt::TrainTrack, branch::Int)
    renamebranch!(tt, branch, -branch)
end


function renameswitch!(tt::TrainTrack, switch::Int, newlabel::Int)
    @assert 1 <= abs(newlabel) <= length(tt.switches)
    @assert !isswitch(tt, newlabel) || abs(newlabel) == abs(switch)

    # When the starting and ending points are the same, we don't want to make changes twice.

    for sgn in (1, -1)
        signedsw = sgn*switch
        for br in outgoing_branches(tt, signedsw)
            _setendpoint!(tt, -br, sgn*newlabel)
        end
    end

    if abs(switch) != abs(newlabel)
        copy(tt.switches[abs(switch)], tt.switches[abs(newlabel)])
        zeroout(tt.switches[abs(switch)])
    end

    if sign(switch) != sign(newlabel)
        sw = tt.switches[abs(newlabel)]
        outgoing = sw.outgoing_branch_indices
        num = sw.numoutgoing_branches
        outgoing[START], outgoing[END] = outgoing[END], outgoing[START]
        num[START], num[END] = num[END], num[START]
    end

end

function reverseswitch!(tt::TrainTrack, switch::Int)
    renameswitch!(tt, switch, -switch)
end



# ------------------------------------
# Utility surgery Operations
# ------------------------------------



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





# ------------------------------------
# Elementary Operations
# ------------------------------------

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

After the collapse, the two endpoints of `b` merge together and, as a result, one switch is removed. The starting switch is kept and the ending switch is deleted.

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

    if istwisted(tt, branch)
        for br in Iterators.flatten((outgoing_branches(tt, -end_sw),
                outgoing_branches(tt, end_sw)))
            twist_branch!(tt, br)
        end
    end

    from_range = BranchRange(end_sw, 1:positions[END][LEFT]-1, end_left)
    to_position = BranchPosition(-start_sw, 0, LEFT)
    _reglue_outgoing_branches!(tt, from_range, to_position)

    from_range = BranchRange(end_sw, 1:positions[END][RIGHT]-1, end_right)
    to_position = BranchPosition(-start_sw, 0, RIGHT)
    _reglue_outgoing_branches!(tt, from_range, to_position)

    insert_pos = outgoing_branch_index(tt, start_sw, branch)
    _delete_outgoing_branches!(tt, BranchRange(start_sw, insert_pos:insert_pos))


    _reglue_outgoing_branches!(
        tt,
        BranchRange(-end_sw, 1:numoutgoing_branches(tt, -end_sw), end_left),
        BranchPosition(start_sw, insert_pos-1))

    _delete_branch!(tt, branch)
    _delete_switch!(tt, end_sw)

    return abs(switch_removed)
end



"""
Inverse of collapsing a branch.

The new switch is the endpoint of the newly created branch and the moved branches are attached to the new switch.

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
            error("At least one branch has to move on the front side and stay on the back side. The specified ranges were $(front_positions_moved.index_range) for the front poisitions and $(back_positions_stay.index_range) for the back positions.")
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


# ----------------------------------------
# Executing Composite Operations
# ----------------------------------------


function execute_elementaryop!(tt::TrainTrack, op::ElementaryTTOperation)
    last_sw, last_br = 0, 0
    if op.optype == PULLING
        last_sw, last_br = pull_switch_apart!(tt, op.front_positions_moved, op.back_positions_stay)
    elseif op.optype == COLLAPSING
        collapse_branch!(tt, op.label1)
    elseif op.optype == RENAME_BRANCH
        renamebranch!(tt, op.label1, op.label2)
    elseif op.optype == RENAME_SWITCH
        renameswitch!(tt, op.label1, op.label2)
    else
        @assert false
    end
    (last_sw, last_br)
end


function substitute_zero_inop(op::ElementaryTTOperation, last_sw::Int, last_br::Int)
    # typ = typeof(op)
    if op.optype == COLLAPSING
        if op.label1 == 0
            return collapsing_op(last_br)
        end
    elseif op.optype == RENAME_BRANCH
        if op.label1 == 0
            return renaming_branch_op(last_br, op.label2)
        end
    elseif op.optype == RENAME_SWITCH
        if op.label1 == 0
            return renaming_switch_op(last_sw, op.label2)
        end
    elseif op.optype == PULLING
        nothing
    else
        @assert false
    end
    return op
end


struct TTOperationIterator
    tt::TrainTrack
    operations::Array{ElementaryTTOperation}
end

# TTOperationIterator(tt::TrainTrack, ops::Array{ElementaryTTOperation}) = TTOperationIterator(tt, ops, 0, 0)

function Base.iterate(ttopiter::TTOperationIterator, state=(0, 0, 0))
    count, last_sw, last_br = state
    count += 1
    if count > length(ttopiter.operations)
        return nothing
    end
    op = ttopiter.operations[count]
    subbed_op = substitute_zero_inop(op, last_sw, last_br)
    ttopiter.operations[count] = subbed_op
    sw, br = execute_elementaryop!(ttopiter.tt, subbed_op)
    if sw != 0
        @assert br != 0  # only pulling creates new branches and switches and in that case both a new switch and a new branch is created
        last_sw = sw
        last_br = br
    end
    return ((ttopiter.tt, subbed_op, last_sw, last_br), (count, last_sw, last_br))
end


function execute_elementaryops!(tt::TrainTrack, ops::Array{ElementaryTTOperation})
    sw, br = 0, 0
    for (tt_afterop, lastop, last_added_switch, last_added_branch) in TTOperationIterator(tt, ops)
        sw, br = last_added_switch, last_added_branch
    end
    sw, br
end


function peel!(tt::TrainTrack, switch::Int, side::Int)
    ops = peeling_to_elementaryops(tt, switch, side)
    execute_elementaryops!(tt, ops)
    nothing
end

function fold!(tt::TrainTrack, switch::Int, side::Int)
    ops = folding_to_elementaryops(tt, switch, side)
    execute_elementaryops!(tt, ops)
    nothing
end

function split_trivalent!(tt::TrainTrack, branch::Int, left_right_or_central::Int)
    ops = split_trivalent_to_elementaryops(tt, branch, left_right_or_central)
    execute_elementaryops!(tt, ops)
    nothing
end

function fold_trivalent!(tt::TrainTrack, branch::Int)
    ops = fold_trivalent_to_elementaryops(tt, branch)
    execute_elementaryops!(tt, ops)
    nothing
end

function add_switch_on_branch!(tt::TrainTrack, branch::Int)
    ops = add_switch_on_branch_to_elementaryops(tt, branch)
    added_sw, added_br = execute_elementaryops!(tt, ops)
    (added_sw, added_br)
end

function delete_two_valent_switch!(tt::TrainTrack, switch::Int)
    ops = delete_two_valent_switch_to_elementaryops(tt, switch)
    execute_elementaryops!(tt, ops)
    nothing
end


end
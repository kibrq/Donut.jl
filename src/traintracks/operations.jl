
module Operations

export twist_branch!, renamebranch!, reversebranch!, reverseswitch!, renameswitch!, add_branch!, delete_branch!, collapse_branch!, pullout_branches!, pull_switch_apart!, add_switch_on_branch!, delete_two_valent_switch!, peel!, fold!, split_trivalent!, fold_trivalent!


using Donut.TrainTracks
using Donut.TrainTracks: _set_extremal_branch!, _set_next_branch!, _setendpoint!, twist_branch!, _find_new_branch_number!, _find_new_switch_number!, _set_twisted!, BranchIterator
using Donut
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD, START, END
using Donut.Utils: otherside
using Donut.TrainTracks.ElementaryOps

# ------------------------------------
# Utility methods
# ------------------------------------




function _detach_branches_unsafe!(iter::BranchIterator)
    # we don't check if start_br can be obtained from end_br by going in start_side direction.
    tt = iter.tt
    start_br = iter.start_br
    end_br = iter.end_br
    start_side = iter.start_side
    # println(start_br, end_br, start_side)

    br1 = next_branch(tt, start_br, start_side)
    br2 = next_branch(tt, end_br, otherside(start_side))
    switch = branch_endpoint(tt, -start_br)
    # println(br1, br2, switch)
    # println("Branch neighbors ", tt.branch_neighbors)
    # println("Extremal branches", tt.extremal_outgoing_branches)

    if br1 == 0
        _set_extremal_branch!(tt, switch, start_side, br2)
    else
        _set_next_branch!(tt, br1, otherside(start_side), br2)
    end
    if br2 == 0
        _set_extremal_branch!(tt, switch, otherside(start_side), br1)
    else
        _set_next_branch!(tt, br2, start_side, br1)
    end
    # println("Branch neighbors ", tt.branch_neighbors)
    # println("Extremal branches", tt.extremal_outgoing_branches)

end


function _attach_branches_unsafe!(
    iter::BranchIterator, target_br::Int, target_side::Int)
    # we don't check if start_br can be obtained from end_br by going in start_side direction.
    tt = iter.tt
    start_br = iter.start_br
    end_br = iter.end_br
    start_side = iter.start_side

    br1 = target_br
    br2 = next_branch(tt, target_br, target_side)
    switch = branch_endpoint(tt, -target_br)

    for br in iter
        _setendpoint!(tt, -br, switch)
    end

    if start_side != target_side
        _set_next_branch!(tt, br1, target_side, start_br)
        _set_next_branch!(tt, start_br, otherside(target_side), br1)
    else
        # if the reading and attaching of the branches happens in opposite directions, we have to relink the whole linked list in the opposite order.
        current_br = start_br
        prev_br = br1
        while prev_br != end_br
            next_br = next_branch(tt, current_br, otherside(start_side))
            _set_next_branch!(tt, prev_br, target_side, current_br)
            _set_next_branch!(tt, current_br, otherside(target_side), prev_br)
            prev_br = current_br
            current_br = next_br
        end
    end
    _set_next_branch!(tt, end_br, target_side, br2)
    if br2 == 0
        _set_extremal_branch!(tt, switch, target_side, end_br)
    else
        _set_next_branch!(tt, br2, otherside(target_side), end_br)
    end


end





# ------------------------------------
# Renaming switches, branches
# ------------------------------------

function renamebranch!(tt::TrainTrack, branch::Int, newlabel::Int)

    @assert 1 <= abs(newlabel) <= size(tt.branch_endpoints)[2]
    @assert !isbranch(tt, newlabel) || abs(newlabel) == abs(branch)

    switches = (branch_endpoint(tt, -branch), branch_endpoint(tt, branch))
    next_branches = ((next_branch(tt, branch, LEFT), next_branch(tt, branch, RIGHT)), 
                    (next_branch(tt, -branch, LEFT), next_branch(tt, -branch, RIGHT)))
    twisted = istwisted(tt, branch)

    for sgn in (1, -1)
        for side in (LEFT, RIGHT)
            _set_next_branch!(tt, sgn*branch, side, 0)
        end
    end

    for i in 1:2
        sw = switches[i]
        sgn = i == 1 ? 1 : -1
        new_br = sgn*newlabel
        for side in (LEFT, RIGHT)
            next_br = next_branches[i][side]
            if next_br != 0
                _set_next_branch!(tt, next_br, otherside(side), new_br)
            else
                _set_extremal_branch!(tt, sw, side, new_br)
            end
            _set_next_branch!(tt, new_br, side, next_br)
        end
    end
    _set_twisted!(tt, newlabel, twisted)
    _set_twisted!(tt, branch, false)
    _setendpoint!(tt, branch, 0)
    _setendpoint!(tt, -branch, 0)
    _setendpoint!(tt, newlabel, switches[2])
    _setendpoint!(tt, -newlabel, switches[1])
end


function reversebranch!(tt::TrainTrack, branch::Int)
    renamebranch!(tt, branch, -branch)
end


function renameswitch!(tt::TrainTrack, switch::Int, newlabel::Int)
    @assert 1 <= abs(newlabel) <= size(tt.extremal_outgoing_branches)[3]
    @assert !isswitch(tt, newlabel) || abs(newlabel) == abs(switch)

    extremal_branches = (
        (extremal_branch(tt, switch, LEFT), extremal_branch(tt, switch, RIGHT)),
        (extremal_branch(tt, -switch, LEFT), extremal_branch(tt, -switch, RIGHT))
    )

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for br in outgoing_branches(tt, sgn*switch)
            _setendpoint!(tt, -br, sgn*newlabel)
        end
    end

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for side in (LEFT, RIGHT)
            _set_extremal_branch!(tt, sgn*switch, side, 0)
        end
    end

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for side in (LEFT, RIGHT)
            _set_extremal_branch!(tt, sgn*newlabel, side, extremal_branches[direction][side])
        end
    end
end

function reverseswitch!(tt::TrainTrack, switch::Int)
    renameswitch!(tt, switch, -switch)
end




"""
Reglue a range of branches from one switch to another.

It updates both the the outgoing branches of switches and endpoints of branches.
"""
function _reglue_outgoing_branches!(
    iter::BranchIterator,
    target_br::Int,
    target_side::Int)

    sw = branch_endpoint(iter.tt, -target_br)

    _detach_branches_unsafe!(iter)
    _attach_branches_unsafe!(iter, target_br, target_side)
end


# ------------------------------------
# Peeling and folding
# ------------------------------------

function peel!(tt::TrainTrack, switch::Int, side::Int)
    if numoutgoing_branches(tt, switch) == 1
        error("Cannot peel at $(switch), because there is only one branch going forward.")
    end

    peeled_branch = extremal_branch(tt, switch, side)
    backward_branch = extremal_branch(tt, -switch, otherside(side))
    back_sw = branch_endpoint(tt, backward_branch)
    back_side = !istwisted(tt, backward_branch) ? side : otherside(side)
    _reglue_outgoing_branches!(BranchIterator(tt, peeled_branch, peeled_branch, side), -backward_branch, back_side)
    if istwisted(tt, backward_branch)
        twist_branch!(tt, peeled_branch)
    end
end


function fold!(tt::TrainTrack, fold_onto_br::Int, folded_br_side::Int)
    folded_br = next_branch(tt, fold_onto_br, folded_br_side)
    if folded_br == 0
        error("There is no branch on the $(folded_br_side==LEFT ? "left" : "right") side of branch $(fold_onto_br).")
    end
    endsw = branch_endpoint(tt, fold_onto_br)
    endside = !istwisted(tt, fold_onto_br) ? otherside(folded_br_side) : folded_br_side
    if extremal_branch(tt, endsw, endside) != -fold_onto_br
        error("Branch $(folded_br) is not foldable on $(fold_onto_br), since there is a branch blocking the fold.")
    end
    far_br = extremal_branch(tt, -endsw, otherside(endside))
    if far_br == folded_br
        # In this case, we are folding up along a loop, so nothing happens.
    else
        _reglue_outgoing_branches!(
            BranchIterator(tt, folded_br), far_br, otherside(endside)
        )
    end
    if istwisted(tt, fold_onto_br)
        twist_branch!(tt, folded_br)
    end
end

# ------------------------------------
# Elementary Operations
# ------------------------------------



function delete_branch!(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)

    for sw in (start_sw, end_sw)
        if numoutgoing_branches(tt, sw) == 1
            error("Branch $(branch) cannot be deleted, one of its endpoints has only one outgoing branches.")
        end
    end
    _detach_branches_unsafe!(BranchIterator(tt, branch))
    _detach_branches_unsafe!(BranchIterator(tt, -branch))
    _setendpoint!(tt, branch, 0)
    _setendpoint!(tt, -branch, 0)
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
    if numoutgoing_branches(tt, start_sw) != 1 || numoutgoing_branches(tt, end_sw) != 1
        error("A branch can only be collapsed if each of its half-branches is the only outgoing branch at their switch.")
    end
    if abs(start_sw) == abs(end_sw)
        error("A branch connecting a switch to itself is not collapsible.")
    end

    switch_removed = end_sw
    twisted = istwisted(tt, branch)

    iter = outgoing_branches(tt, -end_sw, LEFT)
    _reglue_outgoing_branches!(iter, branch, twisted ? LEFT : RIGHT)
    _detach_branches_unsafe!(BranchIterator(tt, branch))
    _detach_branches_unsafe!(BranchIterator(tt, -branch))
    _setendpoint!(tt, branch, 0)
    _setendpoint!(tt, -branch, 0)
    _set_twisted!(tt, branch, false)

    if twisted
        for br in outgoing_branches(tt, start_sw)
            twist_branch!(tt, br)
        end
    end
    # println("Branch neighbors ", tt.branch_neighbors)
    # println("Extremal branches", tt.extremal_outgoing_branches)

    return abs(switch_removed)
end



"""
Inverse of collapsing a branch.

The new switch is the endpoint of the newly created branch and the moved branches are attached to the new switch.

RETURN: (new_switch, new_branch)
"""
function pullout_branches!(iter::BranchIterator)
    tt = iter.tt
    new_sw = _find_new_switch_number!(tt)
    new_br = _find_new_branch_number!(tt)

    br1 = next_branch(tt, iter.start_br, iter.start_side)
    br2 = next_branch(tt, iter.end_br, otherside(iter.start_side))
    sw = branch_endpoint(tt, -iter.start_br)

    _detach_branches_unsafe!(iter)
    if br1 == 0 && br2 == 0
        _set_extremal_branch!(tt, sw, LEFT, new_br)
        _set_extremal_branch!(tt, sw, RIGHT, new_br)
        _setendpoint!(tt, -new_br, sw)
    elseif br1 != 0
        _attach_branches_unsafe!(BranchIterator(tt, new_br), br1, otherside(iter.start_side))
    else
        _attach_branches_unsafe!(BranchIterator(tt, new_br), br2, iter.start_side)
    end
    _set_extremal_branch!(tt, new_sw, LEFT, iter.start_br)
    _set_extremal_branch!(tt, new_sw, RIGHT, iter.end_br)

    _set_extremal_branch!(tt, -new_sw, LEFT, -new_br)
    _set_extremal_branch!(tt, -new_sw, RIGHT, -new_br)
    _setendpoint!(tt, new_br, -new_sw)
    for br in iter
        _setendpoint!(tt, -br, new_sw)
    end

    (new_sw, new_br)
end

function pull_switch_apart!(tt::TrainTrack, sw::Int)
    pullout_branches!(outgoing_branches(tt, sw))
end


#----------------------------------------
# Executing Composite Operations
# ----------------------------------------


function execute_elementaryop!(tt::TrainTrack, op::ElementaryTTOperation)
    last_sw, last_br = 0, 0
    if op.optype == PEEL
        peel!(tt, op.label1, op.label2)
    elseif op.optype == FOLD
        fold!(tt, op.label1, op.label2)
    elseif op.optype == PULLOUT_BRANCHES
        last_sw, last_br = pullout_branches!(BranchIterator(tt, op.label1, op.label2, op.label3))
    elseif op.optype == COLLAPSE_BRANCH
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



function execute_elementaryops!(tt::TrainTrack, ops)
    added_sw, added_br = 0, 0
    for op in ops
        added_sw, added_br = execute_elementaryop!(tt, op)
    end
    added_sw, added_br
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
    # println(ops)
    added_sw, added_br = execute_elementaryops!(tt, ops)
    (added_sw, added_br)
end

function delete_two_valent_switch!(tt::TrainTrack, switch::Int)
    ops = delete_two_valent_switch_to_elementaryops(tt, switch)
    execute_elementaryops!(tt, ops)
    nothing
end


end
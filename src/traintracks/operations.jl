

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
    iter::BranchIterator, target_br::Integer, target_side::Side)
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

function apply_tt_operation!(tt::TrainTrack, op::RenameBranch)::Integer
    @assert 1 <= abs(op.newlabel) <= size(tt.branch_endpoints)[2]
    @assert !isbranch(tt, op.newlabel) || abs(op.newlabel) == abs(op.oldlabel)

    switches = (branch_endpoint(tt, -op.oldlabel), branch_endpoint(tt, op.oldlabel))
    next_branches = ((next_branch(tt, op.oldlabel, LEFT), next_branch(tt, op.oldlabel, RIGHT)), 
                    (next_branch(tt, -op.oldlabel, LEFT), next_branch(tt, -op.oldlabel, RIGHT)))
    twisted = istwisted(tt, op.oldlabel)

    for sgn in (1, -1)
        for side in (LEFT, RIGHT)
            _set_next_branch!(tt, sgn*op.oldlabel, side, 0)
        end
    end

    for i in 1:2
        sw = switches[i]
        sgn = i == 1 ? 1 : -1
        new_br = sgn*op.newlabel
        for side in (LEFT, RIGHT)
            next_br = next_branches[i][Int(side)]
            if next_br != 0
                _set_next_branch!(tt, next_br, otherside(side), new_br)
            else
                _set_extremal_branch!(tt, sw, side, new_br)
            end
            _set_next_branch!(tt, new_br, side, next_br)
        end
    end
    _set_twisted!(tt, op.newlabel, twisted)
    _set_twisted!(tt, op.oldlabel, false)
    _setendpoint!(tt, op.oldlabel, 0)
    _setendpoint!(tt, -op.oldlabel, 0)
    _setendpoint!(tt, op.newlabel, switches[2])
    _setendpoint!(tt, -op.newlabel, switches[1])
    return 0
end



function apply_tt_operation!(tt::TrainTrack, op::RenameSwitch)::Integer
    @assert 1 <= abs(op.newlabel) <= size(tt.extremal_outgoing_branches)[3]
    @assert !isswitch(tt, op.newlabel) || abs(op.newlabel) == abs(op.oldlabel)

    extremal_branches = (
        (extremal_branch(tt, op.oldlabel, LEFT), extremal_branch(tt, op.oldlabel, RIGHT)),
        (extremal_branch(tt, -op.oldlabel, LEFT), extremal_branch(tt, -op.oldlabel, RIGHT))
    )

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for br in outgoing_branches(tt, sgn*op.oldlabel)
            _setendpoint!(tt, -br, sgn*op.newlabel)
        end
    end

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for side in (LEFT, RIGHT)
            _set_extremal_branch!(tt, sgn*op.oldlabel, side, 0)
        end
    end

    for direction in (FORWARD, BACKWARD)
        sgn = direction == FORWARD ? 1 : -1
        for side in (LEFT, RIGHT)
            _set_extremal_branch!(tt, sgn*op.newlabel, side, 
                extremal_branches[Int(direction)][Int(side)])
        end
    end
    return 0
end



"""
Reglue a range of branches from one switch to another.

It updates both the the outgoing branches of switches and endpoints of branches.
"""
function _reglue_outgoing_branches!(
    iter::BranchIterator,
    target_br::Integer,
    target_side::Side)

    sw = branch_endpoint(iter.tt, -target_br)

    _detach_branches_unsafe!(iter)
    _attach_branches_unsafe!(iter, target_br, target_side)
end


# ------------------------------------
# Peeling and folding
# ------------------------------------

function apply_tt_operation!(tt::TrainTrack, op::Peel)::Integer
    if numoutgoing_branches(tt, op.sw) == 1
        error("Cannot peel at $(op.sw), because there is only one branch going forward.")
    end

    peeled_branch = extremal_branch(tt, op.sw, op.side)
    backward_branch = extremal_branch(tt, -op.sw, otherside(op.side))
    back_sw = branch_endpoint(tt, backward_branch)
    back_side = !istwisted(tt, backward_branch) ? op.side : otherside(op.side)
    _reglue_outgoing_branches!(BranchIterator(tt, peeled_branch, peeled_branch, op.side), 
        -backward_branch, back_side)
    if istwisted(tt, backward_branch)
        twist_branch!(tt, peeled_branch)
    end
    return 0
end


function apply_tt_operation!(tt::TrainTrack, op::Fold)::Integer
    folded_br = next_branch(tt, op.fold_onto_br, op.folded_br_side)
    if folded_br == 0
        error("There is no branch on the $(op.folded_br_side==LEFT ? 
            "left" : "right") side of branch $(op.fold_onto_br).")
    end
    endsw = branch_endpoint(tt, op.fold_onto_br)
    endside = !istwisted(tt, op.fold_onto_br) ? otherside(op.folded_br_side) : 
        op.folded_br_side
    if extremal_branch(tt, endsw, endside) != -op.fold_onto_br
        error("Branch $(folded_br) is not foldable on $(op.fold_onto_br), "*
        "since there is a branch blocking the fold.")
    end
    far_br = extremal_branch(tt, -endsw, otherside(endside))
    if far_br == folded_br
        # In this case, we are folding up along a loop, so nothing happens.
    else
        _reglue_outgoing_branches!(
            BranchIterator(tt, folded_br), far_br, otherside(endside)
        )
    end
    if istwisted(tt, op.fold_onto_br)
        twist_branch!(tt, folded_br)
    end
    return 0
end

# ------------------------------------
# Elementary Operations
# ------------------------------------



function apply_tt_operation!(tt::TrainTrack, op::DeleteBranch)::Integer
    start_sw = branch_endpoint(tt, -op.br)
    end_sw = branch_endpoint(tt, op.br)

    for sw in (start_sw, end_sw)
        if numoutgoing_branches(tt, sw) == 1
            error("Branch $(op.br) cannot be deleted, one of its endpoints has only one outgoing branches.")
        end
    end
    _detach_branches_unsafe!(BranchIterator(tt, op.br))
    _detach_branches_unsafe!(BranchIterator(tt, -op.br))
    _setendpoint!(tt, op.br, 0)
    _setendpoint!(tt, -op.br, 0)
    return 0
end


"""
Collapse a branch if possible.

Collapsing a branch `b` is not possible if and only if either the left or right side of `b` has
branches emanating towards `b` from both the ending and the starting point of `b`.

After the collapse, the two endpoints of `b` merge together and, as a result, one switch is removed. The starting switch is kept and the ending switch is deleted.

Return: switch_removed::Integer in absolute value.

"""
function apply_tt_operation!(tt::TrainTrack, op::CollapseBranch)::Integer
    start_sw = branch_endpoint(tt, -op.br)
    end_sw = branch_endpoint(tt, op.br)
    if numoutgoing_branches(tt, start_sw) != 1 || numoutgoing_branches(tt, end_sw) != 1
        error("A branch can only be collapsed if each of its half-branches is the only outgoing branch at their switch.")
    end
    if abs(start_sw) == abs(end_sw)
        error("A branch connecting a switch to itself is not collapsible.")
    end

    switch_removed = end_sw
    twisted = istwisted(tt, op.br)

    iter = outgoing_branches(tt, -end_sw, LEFT)
    _reglue_outgoing_branches!(iter, op.br, twisted ? LEFT : RIGHT)
    _detach_branches_unsafe!(BranchIterator(tt, op.br))
    _detach_branches_unsafe!(BranchIterator(tt, -op.br))
    _setendpoint!(tt, op.br, 0)
    _setendpoint!(tt, -op.br, 0)
    _set_twisted!(tt, op.br, false)

    if twisted
        for br in outgoing_branches(tt, start_sw)
            twist_branch!(tt, br)
        end
    end
    # println("Branch neighbors ", tt.branch_neighbors)
    # println("Extremal branches", tt.extremal_outgoing_branches)

    return -switch_removed
end



"""
Inverse of collapsing a branch.

The new switch is the endpoint of the newly created branch and the moved branches are attached to the new switch.

RETURN: (new_switch, new_branch)
"""
function apply_tt_operation!(tt::TrainTrack, op::PulloutBranches)::Integer
    new_sw = _find_new_switch_number!(tt)
    new_br = _find_new_branch_number!(tt)

    br1 = next_branch(tt, op.start_br, op.start_side)
    br2 = next_branch(tt, op.end_br, otherside(op.start_side))
    sw = branch_endpoint(tt, -op.start_br)

    iter = BranchIterator(tt, op.start_br, op.end_br, op.start_side)
    _detach_branches_unsafe!(iter)
    if br1 == 0 && br2 == 0
        _set_extremal_branch!(tt, sw, LEFT, new_br)
        _set_extremal_branch!(tt, sw, RIGHT, new_br)
        _setendpoint!(tt, -new_br, sw)
    elseif br1 != 0
        _attach_branches_unsafe!(BranchIterator(tt, new_br), br1, otherside(op.start_side))
    else
        _attach_branches_unsafe!(BranchIterator(tt, new_br), br2, op.start_side)
    end
    _set_extremal_branch!(tt, new_sw, LEFT, op.start_br)
    _set_extremal_branch!(tt, new_sw, RIGHT, op.end_br)

    _set_extremal_branch!(tt, -new_sw, LEFT, -new_br)
    _set_extremal_branch!(tt, -new_sw, RIGHT, -new_br)
    _setendpoint!(tt, new_br, -new_sw)
    for br in iter
        _setendpoint!(tt, -br, new_sw)
    end

    return new_sw
end

function new_branch_after_pullout(tt_afterop::TrainTrack, new_sw::Integer)
    return -extremal_branch(tt_afterop, -new_sw, LEFT)
end

function remains_recurrent_after_peel(tt::TrainTrack, switch::Integer, peelside::Side)
    # TODO: We allocate memory here.
    peeledbr = extremal_branch(tt, switch, peelside)
    peeloffbr = extremal_branch(tt, -switch, otherside(peelside))
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



# export CuspHandler, cusps, cusp_to_branch, branch_to_cusp, max_cusp_number, update_cusps_peel!, 
    # update_cusps_fold!, cusp_to_switch, outgoing_cusps, update_cusps_pullout_branches!
import Base.copy


struct CuspHandler
    cusp_to_branch::Array{Int16, 2}
    branch_to_cusp::Array{Int16, 3}

    function CuspHandler(a, b)
        new(a, b)
    end

    function CuspHandler(tt::TrainTrack)
        cusp = 1
        branch_to_cusp = zeros(Int16, 2, 2, numbranches_if_made_trivalent(tt))
        cusp_to_branch = zeros(Int16, 2, numcusps(tt))

        for sw in switches(tt)
            for sgn in (1, -1)
                br = extremal_branch(tt, sgn*sw, LEFT)
                while true
                    next_br = next_branch(tt, br, RIGHT)
                    if next_br == 0
                        break
                    end
                    branch_to_cusp[Int(RIGHT), Int(sign(br) > 0 ? FORWARD : BACKWARD), abs(br)] = cusp
                    branch_to_cusp[Int(LEFT), Int(sign(next_br) > 0 ? FORWARD : BACKWARD), abs(next_br)] = cusp
                    cusp_to_branch[Int(LEFT), cusp] = br
                    cusp_to_branch[Int(RIGHT), cusp] = next_br
                    cusp += 1
                    br = next_br
                end
            end
        end
        new(cusp_to_branch, branch_to_cusp)
    end
end

copy(ch::CuspHandler) = CuspHandler(copy(ch.cusp_to_branch), copy(ch.branch_to_cusp))


function cusp_to_branch(ch::CuspHandler, cusp::Integer, side::Side)
    ch.cusp_to_branch[Int(side), cusp]
end

function branch_to_cusp(ch::CuspHandler, br::Integer, side::Side)
    ch.branch_to_cusp[Int(side), Int(br > 0 ? FORWARD : BACKWARD), abs(br)]
end

# function outgoing_cusps(tt::TrainTrack, ch::CuspHandler, br::Integer, start_side::Side=LEFT)
#     (branch_to_cusp(ch, br, otherside(side)) for br in outgoing_branches(tt, br, side) 
#     if branch_to_cusp(ch, br, otherside(side)) != 0)
# end

function cusp_to_switch(tt::TrainTrack, ch::CuspHandler, cusp::Integer)
    br = cusp_to_branch(ch, cusp, LEFT)
    branch_endpoint(tt, -br)
end

function max_cusp_number(ch::CuspHandler)
    for i in size(ch.cusp_to_branch)[2]:-1:1
        if cusp_to_branch(ch, i, LEFT) != 0
            return i
        end
    end
end

function cusps(ch::CuspHandler)
    (i for i in 1:size(ch.cusp_to_branch)[2] if cusp_to_branch(ch, i, LEFT) != 0)
end

function set_cusp_to_branch!(ch::CuspHandler, cusp::Integer, side::Side, br::Integer)
    ch.cusp_to_branch[Int(side), cusp] = br
end

function set_branch_to_cusp!(ch::CuspHandler, br::Integer, side::Side, cusp::Integer)
    ch.branch_to_cusp[Int(side), Int(br > 0 ? FORWARD : BACKWARD), abs(br)] = cusp
end


function updatecusps_afterop!(tt_after_op::TrainTrack, ch::CuspHandler, op::Peel,
        _::Integer)
    tt = tt_after_op
    peel_off_branch = -extremal_branch(tt, -op.sw, otherside(op.side))
    @assert !istwisted(tt, peel_off_branch)   # TODO: handle twisted branch
    peeled_branch = next_branch(tt, peel_off_branch, op.side)
    forward_branch = extremal_branch(tt, op.sw, op.side)
    cusp = branch_to_cusp(ch, peeled_branch, otherside(op.side))
    next_cusp = branch_to_cusp(ch, peel_off_branch, op.side)

    set_branch_to_cusp!(ch, peel_off_branch, op.side, cusp)
    set_cusp_to_branch!(ch, cusp, otherside(op.side), peel_off_branch)
    set_branch_to_cusp!(ch, forward_branch, op.side, 0)
    if next_cusp != 0
        set_branch_to_cusp!(ch, peeled_branch, op.side, next_cusp)
        set_cusp_to_branch!(ch, next_cusp, otherside(op.side), peeled_branch)
    end
end


function updatecusps_afterop!(tt_after_op::TrainTrack, ch::CuspHandler, op::Fold,
        _::Integer)
    tt = tt_after_op
    @assert !istwisted(tt, op.fold_onto_br)   # TODO: handle twisted branch

    cusp = branch_to_cusp(ch, op.fold_onto_br, op.folded_br_side)
    end_sw = -branch_endpoint(tt, op.fold_onto_br)
    folded_br = extremal_branch(tt, end_sw, op.folded_br_side)
    other_cusp = branch_to_cusp(ch, folded_br, op.folded_br_side)
    other_br = next_branch(tt, folded_br, otherside(op.folded_br_side))

    set_cusp_to_branch!(ch, cusp, otherside(op.folded_br_side), other_br)
    set_branch_to_cusp!(ch, other_br, op.folded_br_side, cusp)
    set_branch_to_cusp!(ch, folded_br, op.folded_br_side, 0)
    set_branch_to_cusp!(ch, op.fold_onto_br, op.folded_br_side, other_cusp)
    if other_cusp != 0
        set_cusp_to_branch!(ch, other_cusp, otherside(op.folded_br_side), op.fold_onto_br)
    end
end


function updatecusps_afterop!(tt_after_op::TrainTrack, ch::CuspHandler, 
        _::PulloutBranches, new_sw::Integer)
    tt = tt_after_op
    new_br = new_branch_after_pullout(tt_after_op, new_sw)
    new_sw = -branch_endpoint(tt, new_br)
    left_br = extremal_branch(tt, new_sw, LEFT)
    right_br = extremal_branch(tt, new_sw, RIGHT)
    left_cusp = branch_to_cusp(ch, left_br, LEFT)
    right_cusp = branch_to_cusp(ch, right_br, RIGHT)
    set_branch_to_cusp!(ch, new_br, LEFT, left_cusp)
    set_branch_to_cusp!(ch, new_br, RIGHT, right_cusp)
    if left_cusp != 0
        set_cusp_to_branch!(ch, left_cusp, RIGHT, new_br)
    end
    if right_cusp != 0 
        set_cusp_to_branch!(ch, right_cusp, LEFT, new_br)
    end
    set_branch_to_cusp!(ch, left_br, LEFT, 0)
    set_branch_to_cusp!(ch, right_br, RIGHT, 0)
end





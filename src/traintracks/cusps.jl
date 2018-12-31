module Cusps

using Donut.TrainTracks
using Donut.TrainTracks: numbranches_if_made_trivalent

export CuspHandler, cusps, cusp_to_branch, branch_to_cusp, max_cusp_number, update_cusps_peel!, 
    update_cusps_fold!, cusp_to_switch, outgoing_cusps, update_cusps_pullout_branches!
import Base.copy
using Donut.Constants: FORWARD, BACKWARD
using Donut.Constants

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

function outgoing_cusps(tt::TrainTrack, ch::CuspHandler, br::Integer, start_side::Side=LEFT)
    (branch_to_cusp(ch, br, otherside(side)) for br in outgoing_branches(tt, br, side) 
    if branch_to_cusp(ch, br, otherside(side)) != 0)
end

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


function update_cusps_peel!(tt_after_op::TrainTrack, ch::CuspHandler, switch::Integer, side::Side)
    tt = tt_after_op
    peel_off_branch = -extremal_branch(tt, -switch, otherside(side))
    @assert !istwisted(tt, peel_off_branch)   # TODO: handle twisted branch
    peeled_branch = next_branch(tt, peel_off_branch, side)
    forward_branch = extremal_branch(tt, switch, side)
    cusp = branch_to_cusp(ch, peeled_branch, otherside(side))
    next_cusp = branch_to_cusp(ch, peel_off_branch, side)

    set_branch_to_cusp!(ch, peel_off_branch, side, cusp)
    set_cusp_to_branch!(ch, cusp, otherside(side), peel_off_branch)
    set_branch_to_cusp!(ch, forward_branch, side, 0)
    if next_cusp != 0
        set_branch_to_cusp!(ch, peeled_branch, side, next_cusp)
        set_cusp_to_branch!(ch, next_cusp, otherside(side), peeled_branch)
    end
end


function update_cusps_fold!(tt_after_op::TrainTrack, ch::CuspHandler, fold_onto_br::Integer, 
        folded_br_side::Side)
    tt = tt_after_op
    @assert !istwisted(tt, fold_onto_br)   # TODO: handle twisted branch

    cusp = branch_to_cusp(ch, fold_onto_br, folded_br_side)
    end_sw = -branch_endpoint(tt, fold_onto_br)
    folded_br = extremal_branch(tt, end_sw, folded_br_side)
    other_cusp = branch_to_cusp(ch, folded_br, folded_br_side)
    other_br = next_branch(tt, folded_br, otherside(folded_br_side))

    set_cusp_to_branch!(ch, cusp, otherside(folded_br_side), other_br)
    set_branch_to_cusp!(ch, other_br, folded_br_side, cusp)
    set_branch_to_cusp!(ch, folded_br, folded_br_side, 0)
    set_branch_to_cusp!(ch, fold_onto_br, folded_br_side, other_cusp)
    if other_cusp != 0
        set_cusp_to_branch!(ch, other_cusp, otherside(folded_br_side), fold_onto_br)
    end
end


function update_cusps_pullout_branches!(tt_after_op::TrainTrack, ch::CuspHandler, new_br::Integer)
    tt = tt_after_op
    front_sw = -branch_endpoint(tt, new_br)
    left_br = extremal_branch(tt, front_sw, LEFT)
    right_br = extremal_branch(tt, front_sw, RIGHT)
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


function updatecusphandler_after_ttop!(tt_afterop::TrainTrack, ch::CuspHandler, 
    op::ElementaryTTOperation, last_added_br::Integer)
    if op.optype == PEEL
        update_cusps_peel!(tt_afterop, ch, op.label1, op.side)
    elseif op.optype == FOLD
        update_cusps_fold!(tt_afterop, ch, op.label1, op.side)
    elseif op.optype == PULLOUT_BRANCHES
        update_cusps_pullout_branches!(tt_afterop, ch, last_added_br)
    elseif op.optype == COLLAPSE_BRANCH
        error("Not yet implemented")
    elseif op.optype == RENAME_BRANCH
        error("Not yet implemented")
    elseif op.optype == RENAME_SWITCH
        error("Not yet implemented")
    elseif op.optype == DELETE_BRANCH
        error("Not yet implemented")
    else
        @assert false
    end
end

end
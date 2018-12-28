module Cusps

using Donut.TrainTracks
using Donut.TrainTracks: numbranches_if_made_trivalent

export CuspHandler, cusps, cusp_to_branch, branch_to_cusp, max_cusp_number, update_cusps_peel!, 
    update_cusps_fold!, cusp_to_switch, outgoing_cusps, update_cusps_pullout_branches!
import Base.copy
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

struct CuspHandler
    cusp_to_branch::Array{Int, 2}
    branch_to_cusp::Array{Int, 3}

    function CuspHandler(a, b)
        new(a, b)
    end

    function CuspHandler(tt::TrainTrack)
        cusp = 1
        branch_to_cusp = zeros(Int, 2, 2, numbranches_if_made_trivalent(tt))
        cusp_to_branch = zeros(Int, 2, numcusps(tt))

        for sw in switches(tt)
            for sgn in (1, -1)
                br = extremal_branch(tt, sgn*sw, LEFT)
                while true
                    next_br = next_branch(tt, br, RIGHT)
                    if next_br == 0
                        break
                    end
                    branch_to_cusp[RIGHT, sign(br) > 0 ? FORWARD : BACKWARD, abs(br)] = cusp
                    branch_to_cusp[LEFT, sign(next_br) > 0 ? FORWARD : BACKWARD, abs(next_br)] = cusp
                    cusp_to_branch[LEFT, cusp] = br
                    cusp_to_branch[RIGHT, cusp] = next_br
                    cusp += 1
                    br = next_br
                end
            end
        end
        new(cusp_to_branch, branch_to_cusp)
    end
end

copy(ch::CuspHandler) = CuspHandler(copy(ch.cusp_to_branch), copy(ch.branch_to_cusp))


function cusp_to_branch(ch::CuspHandler, cusp::Int, side::Int)
    ch.cusp_to_branch[side, cusp]
end

function branch_to_cusp(ch::CuspHandler, br::Int, side::Int)
    ch.branch_to_cusp[side, br > 0 ? FORWARD : BACKWARD, abs(br)]
end

function outgoing_cusps(tt::TrainTrack, ch::CuspHandler, br::Int, start_side::Int=LEFT)
    (branch_to_cusp(ch, br, otherside(side)) for br in outgoing_branches(tt, br, side) 
    if branch_to_cusp(ch, br, otherside(side)) != 0)
end

function cusp_to_switch(tt::TrainTrack, ch::CuspHandler, cusp::Int)
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

function set_cusp_to_branch!(ch::CuspHandler, cusp::Int, side::Int, br::Int)
    ch.cusp_to_branch[side, cusp] = br
end

function set_branch_to_cusp!(ch::CuspHandler, br::Int, side::Int, cusp::Int)
    ch.branch_to_cusp[side, br > 0 ? FORWARD : BACKWARD, abs(br)] = cusp
end


function update_cusps_peel!(tt_before_peel::TrainTrack, ch::CuspHandler, switch::Int, side::Int)
    # tt = tt_before_peel
    # peeled_branch = extremal_branch(tt, switch, side)
    # peel_off_branch = extremal_branch(tt, -switch, otherside(side))
    # cusp = branch_to_cusp(tt, ch, peeled_branch, otherside(side))

    # @assert !is_twisted(tt, peel_off_branch)   # TODO: handle twisted branch
    # if side == LEFT
    #     # if we peel on the left, the branch left of the cusp stays peeled_branch,
    #     # so there is nothing to do
    # else
    #     other_cusp = branch_to_cusp(tt, ch, -peel_off_branch, RIGHT)
    #     set_cusp_to_left_branch!(ch, cusp, LEFT, -peel_off_branch)
    #     set_branch_to_right_cusp!(ch, -peel_off_branch, cusp)
    #     if other_cusp != 0
    #         set_cusp_to_left_branch!(ch, other_cusp, peeled_branch)
    #         set_branch_to_right_cusp!(ch, peeled_branch, other_cusp)
    #     end
    #     new_ext_br = next_branch(tt, peeled_branch, otherside(side))
    #     set_branch_to_right_cusp!(ch, new_ext_br, 0)
    # end
end


function update_cusps_fold!(tt_before_fold::TrainTrack, ch::CuspHandler, fold_onto_br::Int, 
        folded_br_side::Int)
    # tt = tt_before_fold

    # @assert !is_twisted(tt, fold_onto_br)   # TODO: handle twisted branch
    # if folded_br_side == LEFT
    #     # if we fold on the left, the branch left of the cusp stays the folded branch,
    #     # so there is nothing to do
    # else
    #     end_sw = branch_endpoint(tt, fold_onto_br)
    #     end_br = extremal_branch(tt, -end_sw, folded_br_side)
    #     cusp = branch_to_cusp(tt, ch, fold_onto_br, folded_br_side)
    #     folded_br = next_branch(tt, fold_onto_br, folded_br_side)
    #     other_cusp = branch_to_cusp(tt, ch, folded_br, folded_br_side)

    #     set_cusp_to_left_branch!(ch, cusp, end_br)
    #     set_branch_to_right_cusp!(ch, end_br, cusp)
    #     set_branch_to_right_cusp!(ch, folded_br, 0)
    #     if other_cusp != 0
    #         set_branch_to_right_cusp!(ch, fold_onto_br, other_cusp)
    #         set_cusp_to_left_branch!(ch, other_cusp, fold_onto_br)
    #     end
    # end
end


function update_cusps_pullout_branches!(tt_after_op::TrainTrack, ch::CuspHandler, new_br::Int)
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

end
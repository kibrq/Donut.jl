module Cusps

using Donut.TrainTracks
using Donut.TrainTracks: numbranches_if_made_trivalent

export CuspHandler, cusps, cusp_to_branch, branch_to_cusp, max_cusp_number, update_cusps_peel!, 
    update_cusps_fold!, cusp_to_switch, outgoing_cusps
import Base.copy
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

struct CuspHandler
    cusp_to_left_branch::Array{Int}
    branch_to_right_cusp::Array{Int, 2}

    function CuspHandler(a, b)
        new(a, b)
    end

    function CuspHandler(tt::TrainTrack)
        cusp = 1
        branch_to_right_cusp = zeros(Int, 2, numbranches_if_made_trivalent(tt))
        cusp_to_left_branch = zeros(Int, numcusps(tt))

        for br in branches(tt)
            for sgn in (-1, 1)
                if next_branch(tt, sgn*br, RIGHT) != 0
                    branch_to_right_cusp[sgn > 0 ? FORWARD : BACKWARD, br] = cusp
                    cusp_to_left_branch[cusp] = sgn*br
                    cusp += 1
                end
            end
        end
        new(cusp_to_left_branch, branch_to_right_cusp)
    end
end

copy(ch::CuspHandler) = CuspHandler(copy(ch.cusp_to_left_branch), copy(ch.branch_to_right_cusp))


function cusp_to_branch(tt::TrainTrack, ch::CuspHandler, cusp::Int, side::Int)
    br = ch.cusp_to_left_branch[cusp]
    side == LEFT ? br : next_branch(tt, br, RIGHT)
end

function branch_to_cusp(tt::TrainTrack, ch::CuspHandler, br::Int, side::Int)
    if side == LEFT
        br = next_branch(tt, br, LEFT)
    end
    if br == 0
        return 0
    else
        return ch.branch_to_right_cusp[br > 0 ? FORWARD : BACKWARD, abs(br)]
    end
end

function outgoing_cusps(tt::TrainTrack, ch::CuspHandler, br::Int, start_side::Int=LEFT)
    (branch_to_cusp(tt, ch, br, otherside(side)) for br in outgoing_branches(tt, br, side) 
    if branch_to_cusp(tt, ch, br, otherside(side)) != 0)
end

function cusp_to_switch(tt::TrainTrack, ch::CuspHandler, cusp::Int)
    br = cusp_to_branch(tt, ch, cusp, LEFT)
    branch_endpoint(tt, -br)
end

function max_cusp_number(ch::CuspHandler)
    for i in length(ch.cusp_to_left_branch):-1:1
        if ch.cusp_to_left_branch[i] != 0
            return i
        end
    end
end

function cusps(ch::CuspHandler)
    (i for i in eachindex(ch.cusp_to_left_branch) if ch.cusp_to_left_branch[i] != 0)
end

function set_cusp_to_left_branch!(ch::CuspHandler, cusp::Int, br::Int)
    ch.cusp_to_left_branch[cusp] = br
end

function set_branch_to_right_cusp!(ch::CuspHandler, br::Int, cusp::Int)
    ch.branch_to_right_cusp[br > 0 ? FORWARD : BACKWARD, abs(br)] = cusp
end


function update_cusps_peel!(tt_before_peel::TrainTrack, ch::CuspHandler, switch::Int, side::Int)
    tt = tt_before_peel
    peeled_branch = extremal_branch(tt, switch, side)
    peel_off_branch = extremal_branch(tt, -switch, otherside(side))
    cusp = branch_to_cusp(tt, ch, peeled_branch, otherside(side))

    @assert !is_twisted(tt, peel_off_branch)   # TODO: handle twisted branch
    if side == LEFT
        # if we peel on the left, the branch left of the cusp stays peeled_branch,
        # so there is nothing to do
    else
        other_cusp = branch_to_cusp(tt, ch, -peel_off_branch, RIGHT)
        set_cusp_to_left_branch!(ch, cusp, -peel_off_branch)
        set_branch_to_right_cusp!(ch, -peel_off_branch, cusp)
        if other_cusp != 0
            set_cusp_to_left_branch!(ch, other_cusp, peeled_branch)
            set_branch_to_right_cusp!(ch, peeled_branch, other_cusp)
        end
        new_ext_br = next_branch(tt, peeled_branch, otherside(side))
        set_branch_to_right_cusp!(ch, new_ext_br, 0)
    end
end


function update_cusps_fold!(tt_before_fold::TrainTrack, fold_onto_br::Int, folded_br_side::Int)
    tt = tt_before_fold

    @assert !is_twisted(tt, fold_onto_br)   # TODO: handle twisted branch
    if folded_br_side == LEFT
        # if we fold on the left, the branch left of the cusp stays the folded branch,
        # so there is nothing to do
    else
        end_sw = branch_endpoint(tt, fold_onto_br)
        end_br = extremal_branch(tt, -end_sw, folded_br_side)
        cusp = branch_to_cusp(tt, ch, fold_onto_br, folded_br_side)
        folded_br = next_branch(tt, fold_onto_br, folded_br_side)
        other_cusp = branch_to_cusp(tt, ch, folded_br, folded_br_side)

        set_cusp_to_left_branch!(ch, cusp, end_br)
        set_branch_to_right_cusp!(ch, end_br, cusp)
        set_branch_to_right_cusp!(ch, folded_br, 0)
        if other_cusp != 0
            set_branch_to_right_cusp!(ch, fold_onto_br, other_cusp)
            set_cusp_to_left_branch!(ch, other_cusp, fold_onto_br)
        end
    end
end

end
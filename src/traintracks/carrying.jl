
module Carrying

using Donut.TrainTracks
using Donut.TrainTracks: numswitches_if_made_trivalent, numbranches_if_made_trivalent

struct CarryingMap
    large_tt::TrainTrack
    small_tt::TrainTrack
    smallbr_to_cusp::Array{Int, 2} # [START, END] x [small branches]
    cusp_map::Vector{Int} # [small cusps] 
    extremal_intervals::Array{Int, 2}  #  [LEFT,RIGHT] x [large switches]
    next_interval::Array{Int, 2} # [LEFT, RIGHT] x [intervals]
    small_switch_to_click::Vector{Int} # [small switches]
    interval_to_large_switch::Vector{Int}  # [intervals]
    unused_interval_indices::Vector{Int}
    paths::Array{Int, 2} # [small branches + cusp paths] x [large branches x intervals]
    cusp_index_offset::Int
    interval_index_offset::Int

    """
    A train track carrying itself.
    """
    function CarryingMap(tt::TrainTrack)
        numsw = numswitches_if_made_trivalent(tt)
        numbr = numbranches_if_made_trivalent(tt)
        ncusps = numcusps(tt)

        cusp_map = zeros(Int, ncusps)
        smallbr_to_cusp = zeros(Int, 2, numbr)
        cusp_index = 1
        for br in branches(br)
            for direction in (START, END)
                sgn = direction == START ? 1 : -1
                if next_branch(tt, sgn*br, RIGHT) != 0
                    smallbr_to_cusp[direction, br] = cusp_index
                    cusp_map[cusp_index] = sgn*br
                    cusp_index += 1
                end
            end
        end

        extremal_intervals = zeros(Int, 2, numsw)
        next_interval = zeros(Int, 2, 2*numsw)
        small_switch_to_click = zeros(Int, numsw)
        interval_to_large_switch = zeros(Int, 2*numsw)

        i = 1
        for sw in switches(tt)
            extremal_intervals[LEFT, i] = 2*i-1
            extremal_intervals[RIGHT, i] = 2*i
            next_interval[LEFT, 2*i-1] = 0
            next_interval[RIGHT, 2*i-1] = 2*i
            next_interval[LEFT, 2*i] = 2*i-1
            next_interval[RIGHT, 2*i] = 0

            small_switch_to_click[sw] = i
            interval_to_large_switch[2*i-1] = i
            interval_to_large_switch[2*i] = i
            i += 1
        end
        unused_interval_indices = collect(Int, 2*numsw : -1 : 2*i-1)

        paths = zeros(BigInt, numbr + ncusps, numbr + 2*numsw)

        for br in branches(tt)
            paths[br, br] = 1
        end

        cusp_index_offset = numsw
        interval_index_offset = numbr

        new(tt, tt, smallbr_to_cusp, cusp_map, extremal_intervals, next_interval, small_switch_to_click, interval_to_large_switch, unused_interval_indices, paths, cusp_index_offset, interval_index_offset)
    end

end


end
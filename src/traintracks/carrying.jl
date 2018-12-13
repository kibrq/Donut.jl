
module Carrying

export CarryingMap, cusp_nextto_branch

using Donut.TrainTracks
using Donut.TrainTracks: numswitches_if_made_trivalent, numbranches_if_made_trivalent

struct CarryingMap
    large_tt::TrainTrack
    small_tt::TrainTrack
    smallbr_to_cusp::Array{Int, 2} # [START, END] x [small branches]
    cusp_map::Vector{Int} # [small cusps] 
    extremal_intervals::Array{Int, 2}  #  [LEFT,RIGHT] x [large switches]
    next_interval::Array{Int, 2} # [LEFT, RIGHT] x [intervals]
    interval_leftof_smallswitch::Vector{Int} # [small switches]
    interval_to_large_switch::Vector{Int}  # [intervals]
    small_switch_right_of_interval::Vector{Int} # [intervals]
    unused_interval_indices::Vector{Int}
    paths::Array{Int, 2} # [large branches x intervals] x [small branches + cusp paths]
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
        interval_leftof_smallswitch = zeros(Int, numsw)
        interval_to_large_switch = zeros(Int, 2*numsw)
        small_switch_right_of_interval = zeros(Int, 2*numsw)

        i = 1
        for sw in switches(tt)
            extremal_intervals[LEFT, i] = 2*i-1
            extremal_intervals[RIGHT, i] = 2*i
            next_interval[LEFT, 2*i-1] = 0
            next_interval[RIGHT, 2*i-1] = 2*i
            next_interval[LEFT, 2*i] = 2*i-1
            next_interval[RIGHT, 2*i] = 0

            interval_leftof_smallswitch[sw] = 2*i-1
            interval_to_large_switch[2*i-1] = i
            interval_to_large_switch[2*i] = i
            small_switch_right_of_interval[2*i-1] = sw
            i += 1
        end
        unused_interval_indices = collect(Int, 2*numsw : -1 : 2*i-1)

        paths = zeros(BigInt, numbr + 2*numsw, numbr + ncusps)

        for br in branches(tt)
            paths[br, br] = 1
        end

        cusp_index_offset = numsw
        interval_index_offset = numbr

        new(tt, tt, smallbr_to_cusp, cusp_map, extremal_intervals, next_interval, interval_leftof_smallswitch, interval_to_large_switch, small_switch_right_of_interval, unused_interval_indices, paths, cusp_index_offset, interval_index_offset)
    end

end

BRANCH = 0
CUSP = 1
INTERVAL = 1

branch_or_cusp_to_index(cm::CarryingMap, branch_or_cusp::Int, label::Int) = 
branch_or_cusp == BRANCH ? label : label + cm.cusp_index_offset

branch_or_interval_to_index(cm::CarryingMap, branch_or_interval::Int, label::Int) = branch_or_interval == BRANCH ? label : label + cm.interval_index_offset

function cusp_nextto_branch(cm::CarryingMap, br::Int, side::Int)
    tt = cm.small_tt
    if side == LEFT
        br = next_branch(tt, br, LEFT)
    end
    return cm.smallbr_to_cusp[br > 0 ? START : END, abs(br)]
end


function append!(cm::CarryingMap, branch_or_cusp1::Int, append_to_label::Int, branch_or_cusp2::Int, appended_label::Int, with_sign::Int=1)
    idx1 = branch_or_cusp_to_index(branch_or_cusp1, append_to_label)
    idx2 = branch_or_cusp_to_index(branch_or_cusp2, appended_label)
    for i in eachindex(size(cm.paths)[1])
        cm.paths[i, idx1] += with_sign*cm.paths[i, idx2]
    end
end


function add_intersection_with_interval!(cm::CarryingMap, branch_or_cusp::Int, label::Int, interval::Int, with_sign::Int=1)
    idx1 = branch_or_cusp_to_index(branch_or_cusp, label)
    idx2 = branch_or_interval_to_index(INTERVAL, interval)
    cm.paths[idx2, idx1] += with_sign
end

function next_interval(cm::CarryingMap, interval::Int, side::Int)
    return cm.next_interval[side, interval]
end


function small_sw_to_large_sw(cm::CarryingMap, sw::Int)

end

# function interval_next_to_small_switch(cm::CarryingMap, sw::Int, side::Int, interval)
#     if (sw > 0) == (side == RIGHT) 
#         interval = next_iterval(cm, interval, RIGHT)
#     end
#     return sign(sw) * interval
# end

"""
Return the interval on the specified side of the click containing a switch. A signed interval is returned. The sign is positive of the small switch has the same orientation as the large switch. Otherwise the sign is negative.
"""
function interval_next_to_small_switch(cm::CarryingMap, sw::Int, side::Int)
    interval = cm.interval_leftof_smallswitch[abs(sw)]
    if (sw > 0) == (side == RIGHT) 
        interval = next_iterval(cm, interval, RIGHT)
    end
    return sign(sw) * interval
end

function set_interval_next_to_small_switch(cm::CarryingMap, sw::Int, side::Int, interval::Int)
    if sw > 0
        if side == RIGHT
            interval = next_iterval(cm, interval, LEFT)
        end
    else
        if side == LEFT
            interval = next_interval(cm, interval, )
    end

    if (sw > 0) == (side == RIGHT) 
        interval = next_iterval(cm, interval, RIGHT)
    end
    sign(sw) * interval
    cm.interval_leftof_smallswitch[abs(sw)] = interval
end

function get_intersections(cm::CarryingMap, branch_or_cusp::Int, label1::Int, branch_or_interval::Int, label2::Int)
    idx1 = branch_or_cusp_to_index(branch_or_cusp, label1)
    idx2 = branch_or_cusp_to_index(branch_or_interval, label2)
    return cm.paths[idx2, idx1]
end

function is_branch_collapsed(cm::CarryingMap, br::Int)
    for large_br in branches(cm.large_tt)
        if get_intersections(BRANCH, br, BRANCH, large_br) != 0
            return false
        end
    end
    return true
end


"""Applies a function for the switches connected to the endpoint of a
branch by collapsed branches.

The specified branch is not allowed to use as a connection. Hence the
switches considered is a component of a click minus a switch.

INPUT:
- ``branch`` -- a branch of the small train track

"""
function apply_to_switches_in_click_after_branch(cm::CarryingMap, branch::Int, fn::Function)
    sw = branch_endpoint(cm.small_tt, branch)
    return apply_to_switches_in_click(cm, sw, fn, -branch)
end


"""Applies a function for the switches of the small train track in the specified click.

The tree of switches in the click is traversed via collapsed branches. If ``illegal_br`` is nonzero, then we are not allowed to traverse that branch and as a result we get the switches in a component of a click minus a switch.

The traversed switches are all oriented in the same direction as the starting switch. 
"""
function apply_to_switches_in_click(cm::CarryingMap, start_sw::Int, fn::Function, illegal_br::Int=0)
    fn(start_sw)
    for sgn in (-1, 1)
        for br in outgoing_branches(cm.small_tt, sgn*start_sw)
            if br != illegal_br && is_branch_collapsed(cm, br)
                end_sw = branch_endpoint(cm.small_tt, br)
                apply_to_switches_in_click(cm, end_sw, fn, -br)
            end
        end
    end
end



"""Update the carrying map after peeling in the small train track
"""
function peel_in_small!(cm::CarryingMap, switch::Int, side::Int)
    peeled_branch = extremal_branch(cm.small_tt, switch, side)
    thick_branch = extremal_branch(cm.small_tt, -switch, otherside(side))

    is_thick_collapsed = is_branch_collapsed(cm, thick_branch)

    if !is_thick_collapsed
        # if the large branch was collapsed, we could still do the appends,
        # but they would not do anything.
        append!(cm, BRANCH, peeled_branch, BRANCH, thick_branch)
    
        cusp_to_append_to = cusp_nextto_branch(cm, thick_branch, side)
        append!(cm, CUSP, cusp_to_append_to, BRANCH, thick_branch)
    
        is_peeled_collapsed = is_branch_collapsed(cm, peeled_branch)
        interval = interval_next_to_small_switch(cm, switch, side)
        if !is_peeled_collapsed
            # New intersections with an interval next to the switch are
            # only created when none of the two branches are collapsed.
            add_intersection_with_interval!(cm, BRANCH, peeled_branch, abs(interval))
            add_intersection_with_interval!(cm, CUSP, cusp_to_append_to, abs(interval))
        else:
            # If the large branch is not collapsed, but the small branch
            # is, then our click breaks apart after the peeling.
            new_interval = insert_interval!(cm, interval, otherside(side))
            apply_to_switches_in_click_after_branch(cm, peeled_branch, sw -> set_small_switch_to_leftinterval(sw, new_interval) )
            for sw in switches_in_click_after_branch(cm, peeled_branch)
                apply_to_switches_in_click_after_branch()
            end
        end
    end



    # TODO: we need to also update smallbr_to_cusp

    # if not self.is_branch_collapsed(thick_of):
    #     # if the large branch was collapsed, we could still do the appends,
    #     # but they would not do anything.
    #     self.append(BRANCH, peeled_branch, BRANCH, thick_of)
    #     cusp_to_append_to = self._small_tt.adjacent_cusp(
    #     peeled_branch,
    #     side=peeled_side
    #     )
    #     self.append(CUSP, cusp_to_append_to, BRANCH, thick_of)

    #     interval = self.interval_next_to_small_switch(small_switch, LEFT)
    #     if not self.is_branch_collapsed(peeled_branch):
    #         # New intersections with an interval next to the switch are
    #         # only created when none of the two branches are collapsed.
    #         self.add_intersection_with_interval(
    #         BRANCH, peeled_branch, interval)
    #         self.add_intersection_with_interval(
    #         CUSP, cusp_to_append_to, interval)
    #     else:
            # If the large branch is not collapsed, but the small branch
            # is, then our click breaks apart after the peeling.
            new_int, new_click = \
            self.insert_click_next_to_switch(interval, RIGHT)
            for sw in self.get_connected_switches(peeled_branch):
                self.set_small_switch_to_leftinterval(sw, new_click)

    # If the large branch is collapsed, there is nothing to do, because the
    # peeling does not change how long the small branch is. If the small
    # branch is also collapsed, the clicks still do not change.


end
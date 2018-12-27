
module Carrying

export CarryingMap, cusp_nextto_branch

using Donut.TrainTracks
using Donut.TrainTracks: numswitches_if_made_trivalent, numbranches_if_made_trivalent
using Donut.TrainTracks.Cusps

"""

For branches of the small train track, the endpoints are not considered to intersect with any
interval (the endpoints are in a click, not in an interval). For cusps or the small train track,
the corresponding cusp paths is also not considered to interset with any interval at the start
at the path for the same reason. However, it is considered to intersect an interval at the end
of the path is the length of the cusp path is nonzero.

"""
struct CarryingMap
    large_tt::TrainTrack
    small_tt::TrainTrack
    large_cusphandler::CuspHandler
    small_cusphandler::CuspHandler
    small_cusp_to_large_cusp::Vector{Int} # [small cusps] 
    large_cusp_to_small_cusp::Vector{Int} # [large cusps]
    extremal_intervals::Array{Int, 2}  #  [LEFT,RIGHT] x [large switches]
    interval_to_click::Array{Int, 2} # [LEFT, RIGHT] x [intervals]
    click_to_interval::Array{Int, 2} # [LEFT, RIGHT] x [clicks]
    small_switch_to_click::Vector{Int} # [small switches]
    interval_to_large_switch::Vector{Int}  # [intervals]
    click_to_small_switch::Vector{Int} # [clicks]
    unused_interval_indices::Vector{Int}
    unused_click_indices::Vector{Int}
    paths::Array{BigInt, 2} # [large branches x intervals] x [small branches + cusp paths]
    # TODO: break paths into smaller matrices to make computations more efficient if
    # the number of large branches are less than the possible maximum

    temp_intersections::Array{BigInt, 2} # 2 x [small branches + cusp paths]   (2 temporary paths)
    temp_paths::Array{BigInt, 2} # [large branches x intervals] x 2
    cusp_index_offset::Int
    interval_index_offset::Int

    temp_int_array::Array{Int, 2} # [small switches] x 2

    """
    A train track carrying itself.
    """
    function CarryingMap(tt::TrainTrack, ch::CuspHandler)
        numsw = numswitches_if_made_trivalent(tt)
        numbr = numbranches_if_made_trivalent(tt)
        # ncusps = numcusps(tt)

        ncusps = max_cusp_number(ch)

        small_cusp_to_large_cusp = zeros(Int, ncusps)
        large_cusp_to_small_cusp = zeros(Int, ncusps)

        for cusp in cusps(ch)
            small_cusp_to_large_cusp[cusp] = cusp
            large_cusp_to_small_cusp[cusp] = cusp
        end

        extremal_intervals = zeros(Int, 2, numsw)
        interval_to_click = zeros(Int, 2, 2*numsw)
        click_to_interval = zeros(Int, 2, numsw)
        small_switch_to_click = zeros(Int, numsw)
        interval_to_large_switch = zeros(Int, 2*numsw)
        click_to_small_switch = zeros(Int, numsw)

        i = 1
        for sw in switches(tt)
            @assert sw == i
            extremal_intervals[LEFT, i] = 2*i-1
            extremal_intervals[RIGHT, i] = 2*i
            interval_to_click[LEFT, 2*i-1] = 0
            interval_to_click[RIGHT, 2*i-1] = i
            click_to_interval[LEFT, i] = 2*i-1
            interval_to_click[LEFT, 2*i] = i
            click_to_interval[RIGHT, i] = 2*i
            interval_to_click[RIGHT, 2*i] = 0

            small_switch_to_click[sw] = i
            interval_to_large_switch[2*i-1] = i
            interval_to_large_switch[2*i] = i
            click_to_small_switch[i] = sw
            i += 1
        end
        unused_interval_indices = collect(Int, 2*numsw : -1 : 2*i-1)
        unused_click_indices = Int[]

        paths = zeros(BigInt, numbr + 2*numsw, numbr + ncusps)
        temp_intersections = zeros(BigInt, 2, numbr + ncusps)
        temp_paths = zeros(BigInt, numbr + 2*numsw, 1)

        for br in branches(tt)
            paths[br, br] = 1
        end

        cusp_index_offset = numsw
        interval_index_offset = numbr

        temp_int_array = zeros(Int, numsw, 2)

        new(tt, copy(tt), ch, copy(ch),
        small_cusp_to_large_cusp, large_cusp_to_small_cusp, 
        extremal_intervals, interval_to_click, click_to_interval 
        small_switch_to_click, interval_to_large_switch, click_to_small_switch, 
        unused_interval_indices, unused_click_indices, paths, temp_intersections,
        temp_paths, cusp_index_offset, interval_index_offset, temp_int_array)
    end
end

#----------------------------------------------------
# Basic getters and setters
#----------------------------------------------------


small_cusp_to_large_cusp(cm::CarryingMap, small_cusp::Int) = cm.small_cusp_to_large_cusp[small_cusp]
large_cusp_to_small_cusp(cm::CarryingMap, large_cusp::Int) = cm.large_cusp_to_small_cusp[large_cusp]

function click_to_large_switch(cm::CarryingMap, click::Int)
    interval_to_large_switch(cm, click_to_interval(cm, click, LEFT))
end

function small_switch_to_large_switch(cm::CarryingMap, sw::Int)
    click = small_switch_to_click(cm, sw)
    click_to_large_switch(cm, click)
end

"""
Return the interval on the specified side of the click containing a switch. A signed interval is returned. The sign is positive of the small switch has the same orientation as the large switch. Otherwise the sign is negative.
"""
function small_switch_to_click(cm::CarryingMap, sw::Int)
    sign(sw) * cm.small_switch_to_click[abs(sw)]
end

function set_small_switch_to_click!(cm::CarryingMap, sw::Int, click::Int)
    cm.small_switch_to_click[abs(sw)] = sign(sw) * click
end

function click_to_small_switch(cm::CarryingMap, click::Int)
    sign(click) * cm.click_to_small_switch[abs(click)]
end

function set_click_to_small_switch!(cm::CarryingMap, click::Int, sw::Int)
    cm.click_to_small_switch[abs(click)] = sign(click) * sw
end

function interval_to_large_switch(cm::CarryingMap, interval::Int)
    sign(interval) * cm.interval_to_large_switch[abs(interval)]
end

function set_interval_to_large_switch!(cm::CarryingMap, interval::Int, large_sw::Int)
    @assert large_sw == 0 || sign(interval) == sign(large_sw)
    cm.interval_to_large_switch[abs(interval)] = abs(large_sw)
end



#----------------------------------------------------
# Intersections
#----------------------------------------------------


BRANCH = 0
CUSP = 1
INTERVAL = 1
TEMP = 2

branch_or_cusp_to_index(cm::CarryingMap, branch_or_cusp::Int, label::Int) = 
branch_or_cusp == CUSP ? abs(label) + cm.cusp_index_offset : abs(label)

branch_or_interval_to_index(cm::CarryingMap, branch_or_interval::Int, label::Int) = 
    branch_or_interval == INTERVAL ? abs(label) + cm.interval_index_offset : abs(label)


function get_intersections(cm::CarryingMap, branch_or_cusp::Int, label1::Int, branch_or_interval::Int, label2::Int)
    idx1 = branch_or_cusp_to_index(branch_or_cusp, label1)
    idx2 = branch_or_cusp_to_index(branch_or_interval, label2)
    return cm.paths[idx2, idx1]
end

function is_branch_or_cusp_collapsed(cm::CarryingMap, branch_or_cusp::Int, label::Int)
    for large_br in branches(cm.large_tt)
        if get_intersections(cm, branch_or_cusp, label, BRANCH, large_br) != 0
            return false
        end
    end
    return true
end

function add_paths_small!(cm::CarryingMap, branch_cusp_or_temp1::Int, add_to_label::Int, 
    branch_cusp_or_temp2::Int, added_label::Int, with_sign::Int=1)
    idx1 = branch_or_cusp_to_index(branch_cusp_or_temp1, append_to_label)
    idx2 = branch_or_cusp_to_index(branch_cusp_or_temp2, appended_label)
    arr1 = branch_cusp_or_temp1 == TEMP ? cm.temp_paths : cm.paths
    arr2 = branch_cusp_or_temp2 == TEMP ? cm.temp_paths : cm.paths
    for i in eachindex(size(cm.paths)[1])
        arr1[i, idx1] += with_sign*arr2[i, idx2]
    end
end

function add_paths_large!(cm::CarryingMap, branch_interval_or_temp1::Int, add_to_label::Int, 
    branch_interval_or_temp2::Int, added_label::Int, with_sign::Int=1)
    idx1 = branch_or_interval_to_index(branch_interval_or_temp1, add_to_label)
    idx2 = branch_or_interval_to_index(branch_interval_or_temp2, added_label)
    arr1 = branch_interval_or_temp1 == TEMP ? cm.temp_intersections : cm.paths
    arr2 = branch_interval_or_temp2 == TEMP ? cm.temp_intersections : cm.paths
    for i in eachindex(size(cm.paths)[2])
        arr1[idx1, i] += with_sign * arr2[idx2, i]
    end
end

function add_paths_from_click!(cm::CarryingMap, branch_interval_or_temp::Int, add_to_label::Int, 
    click::Int, with_sign::Int=-1)

    forward_paths = forward_branches_and_cusps_from_click(cm, click, LEFT, FORWARD)
    for i in eachindex(forward_paths)
        branch_or_cusp = i % 2 == 0 ? CUSP : BRANCH
        add_intersection!(cm, branch_or_cusp, forward_paths[i], branch_interval_or_temp, add_to_label, -1)            
    end
end

function add_intersection!(cm::CarryingMap, branch_cusp_or_temp::Int, label::Int, branch_interval_or_temp::Int, label2::Int, with_sign::Int=1)
    idx1 = branch_or_cusp_to_index(branch_cusp_or_temp, label)
    idx2 = branch_or_interval_to_index(branch_interval_or_temp, label2)
    arr = branch_interval_or_temp == TEMP ? cm.temp_intersections : cm.paths
    arr[idx2, idx1] += with_sign
end



#---------------------------------------------------
# Clicks and intervals
#---------------------------------------------------



function click_to_interval(cm::CarryingMap, click::Int, side::Int)
    return sign(click)*cm.click_to_interval[click > 0 ? side : otherside(side), abs(click)]
end

function set_click_to_interval!(cm::CarryingMap, click::Int, side::Int, new_value::Int)
    cm.click_to_interval[click > 0 ? side : otherside(side), abs(click)] = abs(click)*new_value
end

function interval_to_click(cm::CarryingMap, interval::Int, side::Int)
    return sign(interval)*cm.interval_to_click[interval > 0 ? side : otherside(side), abs(interval)]
end

function set_interval_to_click!(cm::CarryingMap, interval::Int, side::Int, new_value::Int)
    cm.interval_to_click[interval > 0 ? side : otherside(side), abs(interval)] = abs(interval)*new_value
end


function _create_interval!(cm::CarryingMap)
    @assert length(cm.unused_interval_indices) > 0
    return pop!(cm.unused_interval_indices)
end

function _create_click!(cm::CarryingMap)
    @assert length(cm.unused_click_indices) > 0
    return pop!(cm.unused_click_indices)
end

function _delete_interval!(cm::CarryingMap, interval::Int)
    push!(cm.unused_interval_indices, abs(interval))
    set_interval_to_large_switch!(cm, interval, 0)
    set_interval_to_click!(cm, interval, LEFT) = 0
    set_interval_to_click!(cm, interval, RIGHT) = 0

    idx = branch_or_interval_to_index(INTERVAL, interval)
    cm.paths[idx, :] .= 0
end

function _delete_click!(cm::CarryingMap, click::Int)
    push!(cm.unused_interval_indices, abs(interval))
    set_click_to_interval!(cm, click, LEFT) = 0
    set_click_to_interval!(cm, click, RIGHT) = 0
    set_click_to_small_switch!(cm, click, 0)
end

function extremal_interval(cm::CarryingMap, large_sw::Int, side::Int)
    cm.extremal_intervals[large_sw > 0 ? side : otherside(side), abs(large_sw)]
end

function set_extremal_interval!(cm::CarryingMap, large_sw::Int, side::Int, new_value::Int)
    @assert sign(large_sw) == sign(new_value)
    cm.extremal_intervals[large_sw > 0 ? side : otherside(side), abs(large_sw)] = abs(new_value)
end

"""
Insert a click on a specified side of in interval. A new interval is also created 
on the opposite side of the new click.
"""
function insert_click!(cm::CarryingMap, interval::Int, side::Int)
    new_interval = create_interval!(cm)
    new_interval = sign(interval) * new_interval
    new_click = create_click!(cm)
    new_click = sign(interval) * new_click

    next_click = interval_to_click(cm, interval, side)
    large_sw = interval_to_large_switch(cm, interval)
    set_interval_to_large_switch!(cm, new_interval, large_sw)

    set_interval_to_click!(cm, interval, side, new_click)
    set_click_to_interval!(cm, new_click, otherside(side), interval)
    set_click_to_interval!(cm, new_click, side, new_interval)
    set_interval_to_click!(cm, new_interval, otherside(side), new_click)
    set_interval_to_click!(cm, new_interval, side, next_click)
    if next_click != 0
        set_click_to_interval!(cm, next_click, otherside(side), new_interval)
    else
        set_extremal_interval!(cm, large_sw, side, new_interval)
    end
    new_click, new_interval
end

function delete_click_and_merge!(cm::CarryingMap, click::Int, deleted_interval_side::Int, combine_intersections::Bool=true)
    side = deleted_interval_side
    interval_deleted = click_to_interval(cm, click, side)
    interval_kept = click_to_interval(cm, click, otherside(side))
    next_click = interval_to_click(cm, interval_deleted, side)

    if next_click != 0
        set_click_to_interval!(cm, next_click, otherside(side), interval_kept)
    else
        large_sw = interval_to_large_switch(cm, interval_kept)
        set_extremal_interval!(cm, large_sw, side, interval_kept)
    end
    set_interval_to_click!(cm, interval_kept, side, next_click)

    # Combining the intersections.
    if combine_intersections
        add_paths_large!(cm, INTERVAL, interval_kept, INTERVAL, interval_deleted)
    end

    _delete_click!(click)
    _delete_interval!(interval_deleted)
end




#---------------------------------------------------
# Converting positions
#---------------------------------------------------

"""
Compute the total paths in all outgoing large branches on the specified side of a large cusp.
The result is stored in a preallocated temporary array with specified index.
"""
function compute_paths_on_one_side_of_large_cusp!(cm::CarryingMap, large_cusp::Int, side::Int,
    temp_storage_index::Int)
    cm.temp_intersections[temp_storage_index, :] .= 0

    large_sw = cusp_to_switch(cm.large_tt, cm.large_cusphandler, large_cusp)
    is_flipped = large_sw < 0

    br1 = extremal_branch(cm.large_tt, large_sw, is_flipped ? otherside(side) : side)
    br2 = cusp_to_branch(cm.large_tt, cm.large_cusphandler, large_cusp, side)
    for br in BranchIterator(cm.large_tt, br1, br2, side)
        add_paths_large!(cm, TEMP, temp_storage_index, BRANCH, br)
        lg_cusp = branch_to_cusp(cm.large_tt, cm.large_cusphandler, br, otherside(side))
        sm_cusp = large_cusp_to_small_cusp(cm, lg_cusp)
        if sm_cusp != 0
            # we also need to take this cusp into account, since the intersection of
            # the cusp path with the interval would also be recorded.
            add_intersection!(cm, CUSP, sm_cusp, TEMP, temp_storage_index)
        end
    end
end


"""
Convert the position at a switch of the large train track to
position in an interval. The position is specified by specifying the outgoing paths
at the large switch on the left or on the right of the position. These paths are stored
is a temporary storage whose index is also given as input.

- temp_storage_index -- the index of the intersection array counting the intersections
on side ``start_side```. The intersection at position IS included in this count.

OUTPUT: A triple is returned 
(INTERVAL, interval_label, temp_index) or (CLICK, click_label, temp_index) where 
temp_index is the index of cm.temp_intersections that contains the intersections in the interval 
or outgoing paths from a click on
the side ``starting_side`` of position, again including the position as an intersection.

"""
function position_in_large_switch_to_click_or_interval(cm::CarryingMap, 
    large_sw::Int, start_side::Int, temp_storage_index::Int)
    running_index = temp_storage_index == 2 ? 1 : 2

    arr = cm.temp_intersections
    arr[running_index, :] = arr[temp_storage_index, :] 
    interval = extremal_interval(cm, large_sw, start_side)

    while true
        for i in 1:2
            if i == 1
                add_paths_large!(cm, TEMP, running_index, INTERVAL, interval, -1)
            else
                click = interval_to_click(cm, interval, otherside(start_side))
                add_paths_from_click!(cm, TEMP, running_index, click, -1)
                interval = click_to_interval(cm, click, otherside(start_side))
            end
            if any(arr[running_index, i] > 0 for i in eachindex(size(arr)[2]))
                @assert all(arr[running_index, i] >= 0 for i in eachindex(size(arr)[2]))
                continue
            end
            if i == 1
                add_paths_large!(cm, TEMP, running_index, INTERVAL, interval)
            else
                add_paths_from_click!(cm, TEMP, running_index, click)
            end
            @assert all(arr[running_index, i] >= 0 for i in eachindex(size(arr)[2]))
            return i == 1 ? (INTERVAL, interval, running_index) : (CLICK, click, running_index)
        end
    end

    @assert false
end


function position_in_click_or_interval_to_large_switch(cm::CarryingMap, 
    click_or_interval::Int, label::Int, start_side::Int, temp_storage_index::Int)

    running_index = temp_storage_index == 2 ? 1 : 2    
    arr = cm.temp_intersections
    arr[running_index, :] = arr[temp_storage_index, :] 
    while true
        if click_or_interval == CLICK
            # click_or_interval = INTERVAL
            interval = click_to_interval(cm, click, start_side)
            add_paths_large!(cm, TEMP, running_index, INTERVAL, interval)
        else
            # click_or_interval == CLICK
            click = interval_to_click(cm, interval, start_side)
            if click == 0
                return
            end
            add_paths_from_click!(cm, TEMP, running_index, click)
        end
    end
end


function position_in_click_to_branch_or_cusp(cm::CarryingMap, click::Int, start_side::Int,
    temp_storage_index::Int)

    arr = cm.temp_intersections
    forward_paths = forward_branches_and_cusps_from_click(cm, click, start_side, FORWARD)
    pos = sum(arr[temp_storage_index, i] for i in eachindex(size(arr)[2]))
    return (pos % 2 == 0 ? CUSP : BRANCH, forward_paths[pos])
end

"""

- temp_storage_index -- the index of the array containing the outgoing paths on side
``start_side``, including the branch or cusp itself.
"""
function branch_or_cusp_to_position_in_click(cm::CarryingMap, branch_or_cusp::Int,
    label::Int, start_side::Int, temp_storage_index::Int)

    if branch_or_cusp == BRANCH && is_branch_or_cusp_collapsed(cm, BRANCH, label)
        error("A collapsed branch does not count as an outgoing path from a click.")
    end

    cm.temp_intersections[temp_storage_index, :] .= 0
    
    if branch_or_cusp == BRANCH
        sw = branch_endpoint(cm.small_tt, -label)
    elseif branch_or_cusp == CUSP
        sw = cusp_to_switch(cm.small_cusphandler, label)
    else
        @assert false
    end
    click = small_switch_to_click(cm, sw)

    forward_paths = forward_branches_and_cusps_from_click(cm, click, start_side, FORWARD)
    for i in eachindex(forward_paths)
        current_br_or_cusp = i % 2 == 0 ? CUSP : BRANCH
        add_intersection!(cm, current_br_or_cusp, forward_paths[i], TEMP, temp_storage_index)
        if current_br_or_cusp == branch_or_cusp && forward_paths[i] == label
            return
        end
    end
    @assert false
end




"""Find the click or interval containing a cusp of the large train track.

Two things can happen:
- if a cusp of the small train track is pushed onto the large cusp,
then we there is a containing click. This happens if and only
if the cusp path corresponding to the large cusp is collapsed.
- Otherwise there is a containing interval.

"""
function large_cusp_to_position_in_click_or_interval(cm::CarryingMap, large_cusp::Int, start_side::Int)
    compute_paths_on_one_side_of_large_cusp!(cm, large_cusp, start_side, 1)
    large_sw = cusp_to_switch(cm.large_cusphandler, large_cusp)

    click_or_interval, label, temp_storage_index = position_in_large_switch_to_click_or_interval(
        cm, large_sw, start_side, 1)
    return (click_or_interval, label, temp_storage_index)
end




"""Applies a function for the switches connected to the endpoint of a
branch by collapsed branches.

The specified branch is not allowed to use as a connection. Hence the
switches considered is a component of a click minus a switch.

INPUT:
- ``branch`` -- a branch of the small train track

"""
function apply_to_switches_in_click_after_branch!(cm::CarryingMap, branch::Int, fn::Function)
    sw = branch_endpoint(cm.small_tt, branch)
    return apply_to_switches_in_click!(cm, sw, fn, -branch)
end


"""Applies a function for the switches of the small train track in the specified click.

The tree of switches in the click is traversed via collapsed branches. If ``illegal_br`` is nonzero, then we are not allowed to traverse that branch and as a result we get the switches in a component of a click minus a switch.

The traversed switches are all oriented in the same direction as the starting switch. 
"""
function apply_to_switches_in_click!(cm::CarryingMap, start_sw::Int, fn::Function, illegal_br::Int=0)
    fn(start_sw)
    for sgn in (-1, 1)
        for br in outgoing_branches(cm.small_tt, sgn*start_sw)
            if br != illegal_br && is_branch_or_cusp_collapsed(cm, BRANCH, br)
                end_sw = branch_endpoint(cm.small_tt, br)
                apply_to_switches_in_click!(cm, end_sw, fn, -br)
            end
        end
    end
end



#---------------------------------------------------
# Iterating over branches, switches
#---------------------------------------------------


struct BranchAndCuspIterator
    tt::TrainTrack
    ch::CuspHandler
    sw::Int
end

function Base.iterate(iter::BranchAndCuspIterator, state::Tuple{Int, Int}=(0,0))
    br, branch_or_cusp = state
    if br == 0
        # initial state
        br = extremal_interval(iter.tt, iter.sw, LEFT)
        return ((BRANCH, br), (br, BRANCH))
    else
        if branch_or_cusp == BRANCH
            cusp = branch_to_cusp(iter.ch, br, RIGHT)
            if cusp != 0
                return ((CUSP, cusp), (br, CUSP)))
            else
                return nothing
            end
        else
            br = next_branch(iter.tt, br, RIGHT)
            return ((BRANCH, br), (br, BRANCH))
        end
    end
end

function outgoing_branches_and_cusps(tt::TrainTrack, ch::CuspHandler, sw::Int)
    BranchAndCuspIterator(tt, ch, sw)
end

function save_forward_branches_and_cusps_from_cone(cm::CarryingMap, small_sw::Int, start_side::Int=LEFT, idx::Int=1)
    for (branch_or_cusp, label) in outgoing_branches_and_cusps(cm.small_tt, cm.small_cusphandler, small_sw, start_side)
        if branch_or_cusp == BRANCH && is_branch_or_cusp_collapsed(cm, branch_or_cusp, label)
            br = label
            new_sw = -branch_endpoint(cm.small_tt, br)
            idx = save_forward_branches_and_cusps_from_cone(cm, new_sw, start_side, idx)
        else
            cm.temp_int_array[idx, FORWARD] = label
            @assert (idx % 2 == 0) == (branch_or_cusp == CUSP)
            idx += 1
        end
    end
    return idx
end

function forward_branches_and_cusps_from_cone(cm::CarryingMap, small_sw::Int, start_side::Int)
    length_plus_1 = save_forward_branches_and_cusps_from_cone(cm, small_sw, start_side)
    view(cm.temp_int_array, 1:length_plus_1-1, FORWARD)
    # (label for label in cm.temp_int_array if label != 0)
end

COMING_FROM_BEHIND = 0
COMING_FROM_FRONT_STARTSIDE = 1
COMING_FROM_FRONT_OTHERSIDE = 2

function save_forward_branches_and_cusps_from_click(cm::CarryingMap, small_sw::Int, start_side::Int,
    temp_index::Int, coming_from::Int=COMING_FROM_BEHIND, branch_leading_here::Int=0, idx::Int=1)

    # Recursively collect all branches and cusps on the starting side
    # We do this if COMING_FROM_BEHIND or COMING_FROM_FRONT_OTHERSIDE,
    # but not if COMING_FROM_FRONT_STARTSIDE
    if coming_from != COMING_FROM_FRONT_STARTSIDE
        back_br = extremal_branch(cm.small_tt, -small_sw, otherside(start_side))
        if back_br != -branch_leading_here
            back_sw = branch_endpoint(cm.small_tt, back_br)
            idx = save_forward_branches_and_cusps_from_click(cm, back_sw, start_side, 
                temp_index, COMING_FROM_FRONT_OTHERSIDE, back_br, idx)
        end
    end

    # Determine the forward branches to iterate over.
    if coming_from == COMING_FROM_BEHIND
        # We iterate over all branches
        # The initial step of the recursion is also this case
        iter = outgoing_branches(cm.small_tt, small_sw, start_side)
    elseif coming_from == COMING_FROM_FRONT_STARTSIDE
        end_br = extremal_branch(cm.small_tt, small_sw, otherside(start_side))
        iter = BranchIterator(cm.small_tt, -branch_leading_here, end_br, start_side)
    elseif coming_from == COMING_FROM_FRONT_OTHERSIDE
        start_br = extremal_branch(cm.small_tt, small_sw, start_side)
        iter = BranchIterator(cm.small_tt, start_br, -branch_leading_here, start_side)
    else
        @assert false
    end

    # Iterate over forward branches.
    for br in iter
        if br != -branch_leading_here
            if is_branch_or_cusp_collapsed(cm, BRANCH, br) 
                new_sw = -branch_endpoint(cm.small_tt, br)
                idx = save_forward_branches_and_cusps_from_click(cm, new_sw, start_side, temp_index, 
                    COMING_FROM_BEHIND, -br, idx)
            else
                cm.temp_int_array[idx, temp_index] = br
                idx += 1
            end
        else
            if coming_from == COMING_FROM_FRONT_OTHERSIDE
                # this case, branch_leading_here is the sign for stopping the iteration
                break
            end
        end
        cusp = branch_to_cusp(cm.small_tt, cm.small_cusphandler, br, otherside(start_side))
        if cusp == 0
            break
        end
        cm.temp_int_array[idx, temp_index] = cusp
        idx += 1
    end

    # Recursively iterate over branches and cusps on the other side
    if coming_from != COMING_FROM_FRONT_OTHERSIDE
        back_br = extremal_branch(cm.small_tt, -small_sw, start_side)
        if back_br != -branch_leading_here
            back_sw = branch_endpoint(cm.small_tt, back_br)
            idx = save_forward_branches_and_cusps_from_click(cm, back_sw, start_side,
                temp_index, COMING_FROM_FRONT_STARTSIDE, back_br, idx)
        end
    end

    return idx
end

function forward_branches_and_cusps_from_click(cm::CarryingMap, click::Int, start_side::Int,
        temp_index::Int)
    small_sw = click_to_small_switch(cm, click)
    length_plus_1 = save_forward_branches_and_cusps_from_click(cm, small_sw, start_side, temp_index)
    view(cm.temp_int_array, 1:length_plus_1-1, temp_index)
end

function save_backward_branches_and_cusps_from_cone(cm::CarryingMap, small_sw::Int, start_side::Int, idx::Int=1, prev_branch::Int=0,
    stage::Int=0)
    # stage 0 is when the function is called the very first time (the switch is the vertex of the cone)
    # stage 1 is when the function is called with a switch on start_side
    # stage 2 is when the function is called with a switch on the other side
    if stage == 0 || stage == 1
        first_br = extremal_branch(cm.small_tt, small_sw, start_side)
        if is_branch_or_cusp_collapsed(cm, BRANCH, first_br)
            end_sw = -branch_endpoint(cm.small_tt, first_br)
            idx = save_backward_branches_and_cusps_from_cone(cm, end_sw, start_side, idx, first_br, 1)
        end
    end

    if stage == 0 || stage == 1
        start_br = extremal_branch(cm.small_tt, -small_sw, otherside(start_side))
    else
        start_br = -prev_branch
    end

    if stage == 0 || stage == 2
        end_br = extremal_branch(cm.small_tt, -small_sw, start_side)
    else
        end_br = -prev_branch
    end

    for br in BranchIterator(cm.small_tt, start_br, end_br, otherside(start_side))
        if br == -prev_branch
            cm.temp_int_array[idx, BACKWARD] = br
            @assert idx % 2 == 1
            idx += 1
        end
        cusp = branch_to_cusp(cm.small_cusphandler, br, start_side)
        if cusp != 0
            cm.temp_int_array[idx+1, BACKWARD] = cusp
            @assert idx % 2 == 0
            idx += 1
        end
    end

    if stage == 0 || stage == 2
        last_br = extremal_branch(cm.small_tt, small_sw, otherside(start_side))
        if is_branch_or_cusp_collapsed(cm, BRANCH, last_br)
            end_sw = -branch_endpoint(cm.small_tt, last_br)
            idx = save_backward_branches_and_cusps_from_cone(cm, end_sw, start_side, idx, last_br, 2)
        end
    end

    return idx
end

function backward_branches_and_cusps_from_cone(cm::CarryingMap, small_sw::Int)
    length_plus_1 = save_backward_branches_and_cusps_from_cone(cm, small_sw, start_side)
    view(cm.temp_int_array, 1:length_plus_1-1, BACKWARD)
end




#---------------------------------------------------
# Isotoping
#---------------------------------------------------

function is_path_shorter_or_equal(cm::CarryingMap, branch_or_cusp1::Int, label1::Int, 
    branch_or_cusp2::Int, label2::Int)
    idx1 = branch_or_cusp_to_index(branch_or_cusp1, label1)
    idx2 = branch_or_cusp_to_index(branch_or_cusp2, label2)
    all(cm.paths[i, idx1] <= cm.paths[i, idx2] for i in eachindex(size(cm.paths)[1]))
end



function find_shortest_outgoing_path_from_cone!(cm::CarryingMap, forward_paths::AbstractArray{Int, 1})
    for (i, label) in enumerate(forward_paths)
        branch_or_cusp = i % 2 == 0 ? CUSP : BRANCH
        if all(is_path_shorter_or_equal(cm, branch_or_cusp, label, j % 2 == 0 ? CUSP : BRANCH, label2) 
            for (j, label2) in enumerate(forward_paths))
            return (branch_or_cusp, label)
        end
    end
    @assert false
end


function isotope_cone_as_far_as_possible(cm::CarryingMap, small_sw::Int)
    forward_paths = forward_branches_and_cusps_from_cone(cm, small_sw)
    branch_or_cusp, label = find_shortest_outgoing_path_from_cone!(cm, forward_paths)
    # Note that if there is a branch and cusp path that are of equal length, then
    # the branch path will be found, since that does not include an intersection at
    # the end, but the cusp path does.
    # So if a cusp path is found, that guarantees that no branches are collapsed after
    # the isotopy.

    if is_branch_or_cusp_collapsed(cm, branch_or_cusp, label)
        # all collapsed branches are by definition belong to the cone, so 
        # if there is a collapsed path, that has to correspond to a cusp.
        @assert branch_or_cusp == CUSP
        # In that case, no further isotopy is possible.
        return
    end

    # We make a copy, otherwise subtracting a path from itself would make
    # the shortest path the zero array.
    cm.temp_paths[:, 1] .= 0
    add_paths_small!(cm, TEMP, 1, branch_or_cusp, label)
    # If the shortest path is a cusp path, then we need to remove the
    # interval intersection at the end.
    if branch_or_cusp == CUSP
        cusp = branch_or_cusp
        large_cusp = small_cusp_to_large_cusp(cm, cusp)
        click_or_interval, label, _ =
            large_cusp_to_position_in_click_or_interval(cm, large_cusp, LEFT)
        # The large cusp could only be contained in a click if the small cusp
        # was pushed up on it before the isotopy. But in that case, the isotopy
        # would not be possible, so we would not be here.
        # The large click cannot even be at the end of a click, since the branches
        # on both side of the click are strictly longer than the cusp path.
        @assert click_or_interval == INTERVAL
        interval = label
        add_intersection!(cm, TEMP, 1, INTERVAL, interval, -1)
    end

    backward_paths = backward_branches_and_cusps_from_cone(cm, small_sw)
    
    # If there is non-trivial isotopy, then we begin by breaking up click
    # at the beginning and updating the intersections.
    begin_switch_isotopy!(cm, small_sw, backward_paths)
    # This changes clicks and intervals and intersections at the starting
    # large switch.

    # Modifying paths
    for (i, label) in enumerate(forward_paths)
        branch_or_cusp = i % 2 == 0 ? CUSP : BRANCH
        add_paths_small!(cm, branch_or_cusp, label, TEMP, 1, -1)
    end
    for (i, label) in enumerate(backward_paths)
        branch_or_cusp = i % 2 == 0 ? CUSP : BRANCH
        add_paths_small!(cm, branch_or_cusp, label, TEMP, 1)
    end

    # Finally we merge clicks at the end of the isotopy
    end_switch_isotopy!(cm, small_sw, forward_paths)
end


"""Update clicks, intervals and intersections when after the initial
part of a switch isotopy.

Since we move the switch from the current position, the intervals on
the left and right of it have to be joined and the trailing branches
added to the intersection. Only the trailing branches that were not
collapsed are added. It can also happen that the click does not vanish, 
but instead breaks apart to separate
clicks.
"""
function begin_switch_isotopy!(cm::CarryingMap, small_sw::Int, backward_paths::AbstractArray{Int, 1})
    large_sw = small_switch_to_large_switch(cm, small_sw)

    click = small_switch_to_click(cm, small_sw)

    # First we add intersections on the left.
    left_interval = click_to_interval(cm, click, LEFT)

    # we look backwards, so we starting from the right is the same as left,
    # when looking forward
    # iter = outgoing_branches(cm.small_tt, -small_sw, RIGHT)
    collapsed_br_idx = add_intersections_in_range!(cm, backward_paths, 1:length(backward_paths), left_interval, false, 1)

    if collapsed_br_idx == 0
        # If we did not find any collapsed branches, then we remove the
        # click, delete the interval on the right and add its intersections
        # to the interval on the left.
        delete_click_and_merge!(cm, click, RIGHT)
        return
    end

    # We know that at least one click remains after the isotopy.
    # Next, we add intersections on the right.
    right_interval = next_interval(cm, left_interval, RIGHT)
    collapsed_br_idx2 = add_intersections_in_range!(cm, backward_paths, length(backward_paths):-1:1, right_interval, false, 1)

    current_collapsed_br_idx = collapsed_br_idx
    interval = left_interval
    while current_collapsed_br_idx != collapsed_br_idx2
        click, interval = insert_click!(cm, interval, RIGHT)

        current_collapsed_br = backward_paths[collapsed_br_idx]
        end_sw = branch_endpoint(cm.small_tt, current_collapsed_br)
        set_click_to_small_switch!(cm, click, end_sw)
        apply_to_switches_in_click_after_branch!(cm, current_collapsed_br, 
            sw -> set_small_switch_to_click!(cm, sw, -click))

        # update intersections until we bump into the next collapsed branch

        # we set ignore_collapsed_br_at_start to true, since we start the iteration at
        # a collapsed branch we are not interested in
        current_collapsed_br_idx = add_intersections_in_range!(cm, backward_paths, current_collapsed_br_idx:collapsed_br_idx2, interval, true, 1)
    end

    # Finally, updating the switches belonging to the last click.
    collapsed_br2 = backward_paths[collapsed_br_idx2]
    end_sw = branch_endpoint(cm.small_tt, collapsed_br2)
    set_click_to_small_switch!(cm, click, end_sw)
end


"""
Iterate over a range of outgoing branches and cusps of the small train track and add
or subtract intersections of those branches and cusps with a specified interval. 
If a collapsed branch is found, the function is terminated and the collapsed branch is 
returned. 

- ``ignore_collapsed_br_at_start`` - if true, then the starting branch is skipped when
collapsed

"""
function add_intersections_in_range!(cm::CarryingMap, arr::AbstractArray{Int,1}, range::AbstractRange{Int}, interval::Int,
    ignore_collapsed_br_at_start::Bool, with_sign::Int)

    for i in range
        label = arr[i]
        if i % 2 == 1
            br = label
            if i > 1 || !ignore_collapsed_br_at_start
                # If we find a collapsed branch, we break out to create a new interval
                if is_branch_or_cusp_collapsed(cm, BRANCH, br)
                    return i
                end
                add_intersection!(cm, BRANCH, br, INTERVAL, interval, with_sign)
            end
        else
            cusp = label
            add_intersection!(cm, CUSP, cusp, INTERVAL, interval, with_sign)
        end
    end
    # No collapsed branches were found.
    return 0
end


function find_first_collapsed_br(cm::CarryingMap, arr::AbstractArray{Int,1}, range)
    for i in range
        br = arr[i]
        if is_branch_or_cusp_collapsed(cm, BRANCH, br)
            return i
        end
    end
    return 0
end


"""Update clicks, intervals and intersections at the final part of a
switch isotopy.

Like begin_switch_isotopy(), this involves updating
intersection numbers and creating and merging clicks.
"""
function end_switch_isotopy!(cm::CarryingMap, small_sw::Int, forward_paths::AbstractArray{Int, 1})
    # First we need to find the switch of the large train track where the
    # isotopy gets stuck.

    first_collapsed_br_idx = find_first_collapsed_br(cm, forward_paths, 1:2:length(forward_paths))
    
    if first_collapsed_br_idx == 0
        # No branch is collapsed. Then a cusp has to be collapsed.
        collapsed_cusp_idx = 0
        left_interval = 0
        right_interval = 0
        for cusp_idx in 2:2:length(forward_paths)-1
            cusp = forward_paths[cusp_idx]
            if is_branch_or_cusp_collapsed(cm, CUSP, cusp)
                large_cusp = small_cusp_to_large_cusp(cm, cusp)
                large_sw = cusp_to_switch(cm.large_tt, large_cusp)
                click_or_interval, label, temp_storage_index =
                    large_cusp_to_position_in_click_or_interval(cm, large_cusp, LEFT)
                # The large cusp could only be contained in a click if the small cusp
                # was pushed up on it before the isotopy. But in that case, the isotopy
                # would not be possible, so we would not be here.
                @assert click_or_interval == INTERVAL
                left_interval = label
                # add_intersections_in_range!(cm, forward_paths, 1:length(forward_paths), left_interval, false, -1)
                right_interval, new_click = insert_click!(cm, left_interval, RIGHT)
                apply_to_switches_in_click!(cm, small_sw, sw -> set_small_switch_to_click(cm, sw, new_click))
                set_click_to_small_switch!(cm, new_click, small_sw)
                add_paths_large!(cm, INTERVAL, right_interval, TEMP, temp_storage_index)
                add_paths_large!(cm, INTERVAL, left_interval, TEMP, temp_storage_index, -1)
                collapsed_cusp_idx = cusp_idx
                break
            end
        end
        @assert collapsed_cusp_idx != 0

        # It is possible that there are multiple cusp paths that are collapsed.
        # In that case, creating more intervals is not necessary, but we need to 
        # remove some intersections with the surrounding intervals.

        current_interval = left_interval
        for (i, label) in enumerate(forward_paths)
            branch_or_cusp = i % 2 == 0 ? CUSP : BRANCH
            add_intersection!(cm, branch_or_cusp, label, INTERVAL, current_interval, -1)
            if branch_or_cusp == CUSP && label == collapsed_cusp
                current_interval = right_interval
                # TODO: check if we are not off by 1.
            end
        end
    else
        # There is at least one collapsed branch.

        # Finding the interval left of the first collapsed branch.
        first_collapsed_br = forward_paths[first_collapsed_br_idx]
        left_end_sw = branch_endpoint(cm.small_tt, first_collapsed_br)
        left_click = small_switch_to_click(cm, -left_end_sw)
        left_interval = click_to_interval(cm, left_click, LEFT)

        # subtracting intersections from the interval left of the first collapsed branch.
        left_collapsed_br_idx = add_intersections_in_range!(cm, forward_paths, 1:length(forward_paths), left_interval, false, -1)
        @assert left_collapsed_br_idx == first_collapsed_br_idx

        # Finding the last collapsed branch and the interval to the right of it.
        right_collapsed_br_idx = find_first_collapsed_br(cm, forward_paths, length(forward_paths):-2:1)
        right_collapsed_br = forward_paths[right_collapsed_br_idx]
        right_end_sw = branch_endpoint(cm.small_tt, right_collapsed_br)
        right_click = small_switch_to_click(cm, -right_end_sw)
        right_interval = click_to_interval(cm, click, RIGHT)

        # subtracting intersections from the interval right of the last collapsed branch.
        last_collapsed_br = add_intersections_in_range!(cm, forward_paths, length(forward_paths):-1:1, right_interval, false, -1)
        @assert last_collapsed_br == right_collapsed_br

        # deleting clicks in the middle
        idx = last_collapsed_br_idx
        while idx != first_collapsed_br_idx
            br = br_cusp_arr[idx]
            if is_branch_or_cusp_collapsed(cm, BRANCH, br)
                end_sw = branch_endpoint(cm.small_tt, br)
                current_click = small_switch_to_click(cm, -end_sw)
                delete_click_and_merge!(cm, current_click, LEFT, false)
            end
            idx -= 2
        end
        apply_to_switches_in_click!(cm, small_sw, sw -> set_small_switch_to_click(cm, sw, left_click))
    end
end




#---------------------------------------------------
# Operations
#---------------------------------------------------


"""Update the carrying map after peeling in the small train track
"""
function peel_small!(cm::CarryingMap, switch::Int, side::Int)
    peeled_branch = extremal_branch(cm.small_tt, switch, side)
    thick_branch = extremal_branch(cm.small_tt, -switch, otherside(side))

    is_thick_collapsed = is_branch_or_cusp_collapsed(cm, BRANCH, thick_branch)

    if !is_thick_collapsed
        is_peeled_collapsed = is_branch_or_cusp_collapsed(cm, BRANCH, peeled_branch)

        # if the large branch was collapsed, we could still do the appends,
        # but they would not do anything.
        add_paths_small!(cm, BRANCH, peeled_branch, BRANCH, thick_branch)
    
        cusp_to_append_to = branch_to_cusp(cm.small_tt, cm.small_cusphandler, thick_branch, side)
        add_paths_small!(cm, CUSP, cusp_to_append_to, BRANCH, thick_branch)
    
        click = small_switch_to_click(cm, switch)
        interval = click_to_interval(cm, click, side)
        if !is_peeled_collapsed
            # New intersections with an interval next to the switch are
            # only created when none of the two branches are collapsed.
            add_intersection!(cm, BRANCH, peeled_branch, INTERVAL, interval)
            add_intersection!(cm, CUSP, cusp_to_append_to, INTERVAL, interval)
        else:
            # If the peel_off_of branch is not collapsed, but the peeled branch
            # is, then our click breaks apart after the peeling.
            new_click, new_interval = insert_click!(cm, interval, otherside(side))
            end_sw = branch_endpoint(cm.small_tt, peeled_branch)
            set_click_to_small_switch(cm, new_click, -end_sw)
            apply_to_switches_in_click_after_branch!(cm, peeled_branch, sw -> set_small_switch_to_click!(cm, sw, new_click))
            add_intersection!(cm, CUSP, cusp_to_append_to, INTERVAL, new_interval)
        end
    end

end


function fold_large!(cm::CarryingMap, folded_branch::Int, fold_onto_branch::Int,
    folded_branch_side::Int)
    # Adding the intersections with the folded branch to fold_onto_branch ...
    add_paths_large!(cm, BRANCH, fold_onto_branch, BRANCH, folded_branch)

    # ... and also the left- or rightmost interval at the merged switch
    large_sw = branch_endpoint(cm.large_tt, fold_onto_branch)
    # TODO: twisted branch
    interval = extremal_interval(cm, large_sw, folded_branch_side)
    add_paths_large!(cm, INTERVAL, interval, BRANCH, folded_branch)

    # Also add branch and interval intersection with a cusp path, since the
    # cusp path at between the folded branches become longer.
    large_cusp = branch_to_cusp(cm.large_tt, cm.large_cusphandler, fold_onto_branch, folded_branch_side)
    small_cusp = large_cusp_to_small_cusp(cm, large_cusp)
    if small_cusp != 0 
        add_intersection!(cm, CUSP, small_cusp, BRANCH, fold_onto_branch)
        add_intersection!(cm, CUSP, small_cusp, INTERVAL, interval)
    end
end






"""
Decide if there is a cusp blocking the isotopy.
"""
function is_isotopy_stuck_at_cusp(cm::CarryingMap, sw::Int)
    forward_paths = forward_branches_and_cusps_from_cone(cm, sw)
    for (i, label) in enumerate(forward_paths)
        if i % 2 == 0 && is_branch_or_cusp_collapsed(cm, CUSP, label)
            # If a cusp is collapsed, there is no way to isotope further.
            return true
        end
    end
    return false
end



"""Perform a fold in the small train track if possible.
"""
function fold_small!(cm::CarryingMap, folded_branch::Int, fold_onto_branch::Int,
    folded_branch_side::Int)

    # Trying to isotope the endpoint of ``fold_onto_branch`` as close to
    # the start point as possible...
    small_tt = self._small_tt
    end_sw = branch_endpoint(cm.small_tt, fold_onto_branch)
    is_isotopy_stuck = false
    is_fold_possible = false
    while true
        is_isotopy_stuck = is_isotopy_stuck_at_cusp(cm, end_sw)
        if is_isotopy_stuck
            break
        end
        if is_branch_or_cusp_collapsed(cm, BRANCH, fold_onto_branch)
            # If the desired branch is collapsed, we can also stop.
            is_fold_possible = true
            break
        end
        isotope_cone_as_far_as_possible!(cm, end_sw)
        # The process has to finish, because at every iteration there are more switches
        # in the cone that is being pushed forward.

        # TODO: it can happen though that we isotope a switch and it bumps into itself. 
        # In that case, the number of switches in the cone does not increase and can take
        # a really long time until the isotopy is finished. So when performing the isotopy, we shouldn't
        # take into account such returning branches in the minimal path calculation.
        # Whether this is actually comes up and causes a problem, I'm not sure.
    end

    if !is_fold_possible
        # fold_onto_branch is not collapsed
        # ... and isotoping the endpoint of ``folded_branch`` as far as
        # possible.
        folded_end_sw = branch_endpoint(cm.small_tt, folded_branch)


        cusp = branch_to_cusp(cm.small_cusphandler, fold_onto_branch, folded_branch_side)
        if !is_path_shorter_or_equal(cm, BRANCH, fold_onto_branch, CUSP, cusp)
            # In order for the fold to be possible, after the isotopy,
            # fold_onto_branch has to be shorter or equal than the cusp path
            # between the folded and the fold_onto_branch.
            break
        end
        while true
            # Also, the folded_branch has to be at least as long as the fold_onto_branch.
            if is_path_shorter_or_equal(cm, BRANCH, fold_onto_branch, BRANCH, folded_branch)
                is_fold_possible = true
                break
            end
            if is_isotopy_stuck_at_cusp(cm, -folded_end_sw)
                # Folded branch is still not long enough and no more isotopy is possible.
                # In this case, the fold is not possible.
                break
            end
            isotope_cone_as_far_as_possible!(cm, -folded_end_sw)
        end
    end

    if !is_fold_possible
        error("The folded small train track is not carried on \
        the large train track!")
    end

    add_paths_small!(cm, BRANCH, folded_branch, BRANCH, fold_onto_branch, -1)
    add_paths_small!(cm, CUSP, cusp, BRANCH, fold_onto_branch, -1)

    if !is_branch_or_cusp_collapsed(cm, BRANCH, folded_branch)
        click = small_switch_to_click(cm, end_sw)
        interval = click_to_interval(cm, click, folded_branch_side)
        add_intersection!(cm, BRANCH, folded_branch, INTERVAL, interval, -1)
        if !is_branch_or_cusp_collapsed(cm, CUSP, cusp)
            add_intersection!(cm, CUSP, cusp, INTERVAL, interval, -1)
        end

    elseif !is_branch_or_cusp_collapsed(cm, BRANCH, fold_onto_branch)
        # Clicks get merged. This happens when the folded and fold_onto
        # branches where not collapsed but they had the same length.

    end

    # cusp = small_tt.adjacent_cusp(folded_branch, fold_direction)
    # cusp_path = self.path_coordinates(CUSP, cusp)
    # fold_onto_path = self.path_coordinates(BRANCH, fold_onto_branch)
    # folded_path = self.path_coordinates(BRANCH, folded_branch)
    # if is_smaller_or_equal(fold_onto_path, cusp_path) and \
    #         is_smaller_or_equal(fold_onto_path, folded_path):
        # self.append(BRANCH, folded_branch, BRANCH, fold_onto_branch,
                    # with_sign=-1)
        # self.append(CUSP, cusp, BRANCH, fold_onto_branch, with_sign=-1)

        if not self.is_branch_collapsed(folded_branch):
            interval = self.interval_next_to_small_switch(
                end_sw, fold_direction
            )
            self.add_intersection_with_interval(
                BRANCH, folded_branch, interval, -1
            )
            self.add_intersection_with_interval(
                CUSP, cusp, interval, -1
            )
        elif not self.is_branch_collapsed(fold_onto_branch):
            # Just like in the case of peeling there is a scenario when
            # clicks get merged. This happens when the folded and fold_onto
            # branches where not collapsed but they had the same length.
            fold_onto_click = self.small_switch_to_click(fold_onto_branch)
            folded_click = self.small_switch_to_click(folded_branch)
            for sw in self.get_connected_switches(folded_branch):
                self.set_small_switch_to_click(sw, fold_onto_click)
            self.delete_click_and_merge(folded_click, RIGHT)
    # else:
    #     raise FoldError("The folded small train track is not carried on \
    #     the large train track!")
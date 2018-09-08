

const START = 1
const END = 2
const LEFT = 1
const RIGHT = 2
const FORWARD = 1
const BACKWARD = 2

mutable struct Branch
    endpoint::Array{Int,1}  # dim: (2), indexed by START, END
    # or_rev::Array{Bool,1}  # dim: (2), indexed by START, END
    is_twisted::Bool
end

# Branch() = Branch(Int[0, 0], Bool[false, false])
Branch() = Branch(Int[0, 0], false)
is_phantom(br::Branch) = br.endpoint[1] == 0

struct Switch
    outgoing_branch_indices::Array{Array{Int,1},1}  # dim: (2, max_num_branches)
    num_outgoing_branches::Array{Int,1}  # dim: (2), indexed by FORWARD, BACKWARD
end

Switch() = Switch([Int[], Int[]], Int[0, 0])



struct TrainTrack
    branches::Array{Branch,1}
    switches::Array{Switch,1}

    function TrainTrack(gluing_list::Array{Array{Int,1},1},
                        twisted_branches::Array{Int,1}=Int[])
        if length(gluing_list) % 2 == 1
            error("The length of the gluing list must be even.")
        end

        for ls in gluing_list
            if length(ls) == 0
                error("Each array should be non-empty")
            end
        end

        all_branches = sort(collect(Iterators.flatten(gluing_list)))
        if length(all_branches) % 2 != 0
            error("The total number of indices in the input should be even.")
        end

        half_len = div(length(all_branches), 2)
        for i in 1:half_len
            if all_branches[i] != -all_branches[2*half_len - i + 1]
                error("The negative of each index must also appear in the list.")
            end
        end
        for i in 2:half_len+1
            if all_branches[i] == all_branches[i-1]
                error("Every index should appear in the gluing list at most once.")
            end
        end

        branch_arr_size = maximum(maximum(abs(x) for x in y) for y in gluing_list)
        switch_arr_size = div(length(gluing_list), 2)

        branches = [Branch(Int[0, 0], i in twisted_branches) for i in 1:branch_arr_size]
        switches = [Switch([fill(0, branch_arr_size),
                            fill(0, branch_arr_size)],
                           Int[0, 0]) for i in 1:switch_arr_size]

        for i in 1:switch_arr_size
            for step in (FORWARD, BACKWARD)
                sgn = step == FORWARD ? 1 : -1
                ls = gluing_list[2*i - 2 + step]
                for br_idx in ls
                    set_endpoint!(-br_idx, sgn*i, branches)
                end
                switches[i].num_outgoing_branches[step] = length(ls)
                switches[i].outgoing_branch_indices[step][1:length(ls)] = ls
            end
        end

        new(branches, switches)
    end
end

# branch_endpoint(br_idx::Int, branch_array::Array[Branch]) = br_idx > 0 ?
#     branch_array[br_idx].endpoint[END] :
#     branch_array[-br_idx].endpoint[START]

set_endpoint!(br_idx::Int, sw_idx::Int, branch_array::Array{Branch}) = br_idx > 0 ?
    branch_array[br_idx].endpoint[END] = sw_idx :
    branch_array[-br_idx].endpoint[START] = sw_idx

"""Tested"""
other_side(side::Int) = (@assert side in (1,2); side == 1 ? 2 : 1)

"""Tested"""
branch_endpoint(tt::TrainTrack, branch::Int) = tt.branches[abs(branch)].endpoint[
    branch > 0 ? END : START]

"""Tested"""
num_outgoing_branches(tt::TrainTrack, switch::Int) =
    tt.switches[abs(switch)].num_outgoing_branches[switch > 0 ? FORWARD : BACKWARD]

"""Tested"""
set_num_outgoing_branches!(tt::TrainTrack, switch::Int, number::Int) =
    tt.switches[abs(switch)].num_outgoing_branches[switch > 0 ? FORWARD : BACKWARD] = number


"""
Inserts some outgoing branches to the specified switch a the specified position.

Only the branch indices are inserted.


"""
function splice_outgoing_branches!(tt::TrainTrack, switch::Int, index_range::UnitRange{Int}, inserted_branches =
                                   AbstractArray{Int, 1}, start_side::Int=LEFT)
    num_br = num_outgoing_branches(tt, switch)
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

    # cond1 = index_range.start <= 0
    # cond2 = index_range.start > n+1
    # cond3 = index_range.start == n+1 && index_range.stop != n
    # cond4 = index_range.stop > n
    # if cond1 || cond2 || cond3 || cond4

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
    set_num_outgoing_branches!(tt, switch, new_total)

    # arr_view = outgoing_branches(tt, switch)

    # num_existing_branches = num_outgoing_branches(tt, switch)
    # num_added_branches = length(inserted_branches)
    # new_total = num_existing_branches + num_added_branches
    # set_num_outgoing_branches!(tt, switch, new_total)

    # # If not enough space, allocate more
    # direction = switch > 0 ? FORWARD : BACKWARD
    # full_arr = tt.switches[abs(switch)].outgoing_branch_indices[direction]
    # missing = new_total - length(full_arr)
    # if missing > 0
    #     append!(full_arr, fill(0, missing))
    # end

    # if insert_after_pos < 0 || insert_after_pos > num_existing_branches
    #     error("Position $(insert_after_pos) is out of range at switch $(switch).")
    # end

    # end_pos = start_side == LEFT ? insert_after_pos+1 : num_existing_branches+1-insert_after_pos

    # for i in num_existing_branches:-1:end_pos
    #     full_arr[i + num_added_branches] = full_arr[i]
    # end

    # oriented_ins_branches = start_side == LEFT ? inserted_branches : reverse(inserted_branches)
    # full_arr[end_pos:end_pos + num_added_branches - 1] = oriented_ins_branches

end

"""Tested"""
function insert_outgoing_branches!(tt::TrainTrack, switch::Int, insert_pos, inserted_branches =
                                   AbstractArray{Int, 1}, start_side::Int=LEFT)
    splice_outgoing_branches!(tt, switch, insert_pos+1:insert_pos, inserted_branches, start_side)
end

"""Tested"""
function delete_outgoing_branches!(tt::TrainTrack, switch::Int, index_range::UnitRange{Int}, start_side::Int=LEFT)
    splice_outgoing_branches!(tt, switch, index_range, Int[], start_side)
end

"""Tested"""
function outgoing_branches(tt::TrainTrack, switch::Int, start_side::Int=LEFT)
    n = num_outgoing_branches(tt, switch)
    direction = switch > 0 ? FORWARD : BACKWARD
    arr_view = view(tt.switches[abs(switch)].outgoing_branch_indices[direction], 1:n)
    return start_side == LEFT ? arr_view : reverse(arr_view)
end

"""Tested"""
function outgoing_branch(tt::TrainTrack, switch::Int, index::Int, start_side::Int=LEFT)
    n = num_outgoing_branches(tt, switch)
    if index <= 0 || index > n
        error("Index $(index) is invalid at switch $(switch). The number of outgoing branches is $(n).")
    end
    branches = outgoing_branches(tt, switch, start_side)
    branches[index]
end

"""Tested"""
function outgoing_branch_index(tt::TrainTrack, switch::Int, branch::Int, start_side::Int=LEFT)
    branches = outgoing_branches(tt, switch, start_side)
    index = findfirst(isequal(branch), branches)
    if index == nothing
        error("Branch $(branch) is not outgoing from switch $(switch).")
    end
    index
end

"""Tested"""
is_twisted(tt::TrainTrack, branch::Int) = tt.branches[abs(branch)].is_twisted

"""Tested"""
twist_branch!(tt::TrainTrack, branch::Int) = (tt.branches[abs(branch)].is_twisted = !tt.branches[abs(branch)].is_twisted)


"""Tested"""
switch_valence(tt::TrainTrack, switch::Int) = num_outgoing_branches(tt, switch) + num_outgoing_branches(tt, -switch)

"""Tested"""
delete_branch!(tt::TrainTrack, branch::Int) = (tt.branches[abs(branch)] = Branch())

"""Tested"""
delete_switch!(tt::TrainTrack, switch::Int) = (tt.switches[abs(switch)] = Switch())

"""
Collapse a branch if possible.

Collapsing a branch `b` is not possible if and only if either the left or right side of `b` has
branches emanating towards `b` from both the ending and the starting point of `b`.

After the collapse, the two endpoints of `b` merge together and, as a result, one switch is removed.

Return: switch_removed::Int in absolute value.

"""
function collapse_branch!(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    switch_removed = end_sw

    if abs(start_sw) == abs(end_sw)
        error("A branch connecting a switch to itself is not collapsible.")
    end

    # end_left
    if is_twisted(tt, branch)
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

    insert_outgoing_branches!(tt, -start_sw, 0, outgoing_branches(tt, end_sw, end_left)[1:positions[END][LEFT]-1], LEFT)
    insert_outgoing_branches!(tt, -start_sw, 0, outgoing_branches(tt, end_sw, end_right)[1:positions[END][RIGHT]-1], RIGHT)


    insert_pos = outgoing_branch_index(tt, start_sw, branch)
    far_side_branches = outgoing_branches(tt, -end_sw, end_left)
    splice_outgoing_branches!(tt, start_sw, insert_pos:insert_pos, far_side_branches)

    if is_twisted(tt, branch)
        for br in far_side_branches
            twist_branch!(tt, br)
        end
    end

    # delete `branch` and `end_sw`
    delete_branch!(tt, branch)
    delete_switch!(tt, end_sw)

    return abs(switch_removed)
end




"""
Delete a two-valent switch.

If the switch is not two-valent, an error is thrown.

Return: (br_kept, br_removed) -- the branch kept and the branched removed
"""
function delete_two_valent_switch!(tt::TrainTrack, switch::Int)
    assert(switch_valence(tt, switch) == 2)

    # Keep the forward branch and delete the backward branch
    br_kept = outgoing_branch(tt, switch, 1)
    br_removed = outgoing_brach(tt, -switch, 1)
    if br_kept == -br_removed
        error("A switch cannot be deleted if it is the only switch on a curve.")
    end

end



"""

The old switch number is inherited by the "tip" of the split, that is, the resulting 3-valent
switch. The three resulting switches are oriented in the same way as the original switch. The two
new branches are oriented in the same direction as the switches

Return: (sw_left, sw_right, br_left, br_right) -- the two new switch numbers, to the left and right
of the split, and the two new branch numbers, to the left and right of the split.
"""
function split_slightly!(tt::TrainTrack, switch::Int, cusp_idx::Int, split_br_idx::Int)

end

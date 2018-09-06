

const START = 1
const END = 2
const LEFT = 1
const RIGHT = 2
const FORWARD = 1
const BACKWARD = 2

struct Branch
    end_switch_index::Array{Int,1}  # dim: (2), indexed by START, END
    or_rev::Array{Bool,1}  # dim: (2), indexed by START, END
end

Branch() = Branch(Int[0, 0], Bool[false, false])
is_phantom(br::Branch) = br.end_switch_index[1] == 0

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

        branches = [Branch() for i in 1:branch_arr_size]
        switches = [Switch([fill(0, branch_arr_size),
                            fill(0, branch_arr_size)],
                           Int[0, 0]) for i in 1:switch_arr_size]

        for i in 1:switch_arr_size
            if step in (FORWARD, BACKWARD)
                sgn = step == FORWARD ? BACKWARD : -1
                ls = gluing_list[2*i -2 + step]
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
#     branch_array[br_idx].end_switch_index[END] :
#     branch_array[-br_idx].end_switch_index[START]

set_endpoint!(br_idx::Int, sw_idx::Int, branch_array::Array{Branch}) = br_idx > 0 ?
    branch_array[br_idx].end_switch_index[END] = sw_idx :
    branch_array[-br_idx].end_switch_index[START] = sw_idx


    # (branch_endpoint(br_idx, branch_array) = sw_idx; nothing)

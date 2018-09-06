mutable struct Branch
    end_switch_index::Array[Int]
    or_rev::Array[Bool]
end

Branch() = Branch(0, 0, false, false)
is_phantom(br::Branch) = end_switch_index == 0

struct Switch
    outgoing_branch_indices::Array{Int,2}
    num_outgoing_branches::Array{Int}
    # backward_branch_indices::Array{Int}
    # num_backward_branches::Int
end

Switch() = Switch(Int[],0,Int[],0)

# mutable struct Cusp
#     left_branch_index::Int
#     right_branch_index::Int
# end


struct TrainTrack
    # branches::Array{Branch}
    # switches::Array{Switch}

    outgoing_branches::Array

    function TrainTrack(gluing_list::Array{Array{Int}},
                        twisted_branches::Array{Int}=Int[])
        if length(gluing_list) % 2 == 1
            error("The length of the gluing list must be even.")
        end

        branch_arr_size = max(max(abs(x) for x in y) for y in gluing_list)
        switch_arr_size = div(length(gluing_list), 2)

        branches = fill(Branch(), branch_arr_size)
        switches = fill(Switch(Int[0, 0], fill(0, (2, branch_arr_size)), switch_arr_size)

        # num_branches = div(sum(length(x) for x in gluing_list), 2)

        for i in 1::switch_arr_size
            switches[i].num_outgoing_branches = Int[0, 0]
            switches[
            if step in 1::2
                sgn = step == 0 ? 1 : -1
                ls = gluing_list[2*i -2 + step]
                for br_idx in ls
                    # Check if br_idx occurs only once
                    set_endpoint(-br_idx, sgn*i, branches)
                end
                switches[i].num_outgoing_branches[step] = length(ls)
                switches[i].outgoing_branch_indices[step
                if step == 1
                    switches[i].num_forward_branches = length(ls)
                    switches[i].forward_branch_indices = copy(ls)
                else
                    switches[i].num_backward_branches = length(ls)
                    switches[i].backward_branch_indices = copy(ls)



        new(branches, switches)
    end
end

set_endpoint(br_idx::Int, sw_idx::Int, branch_array::Array[Branch]) = br_idx > 0 ?
    branch_array[br_idx].end_switch_index = sw_idx :
    branch_array[-br_idx].start_switch_index = sw_idx


# struct TrainTrack2
#     branch_endpoints::Array{Int}
#     branch_startpoints::Array{Int}
# end


# function fill1(tt::TrainTrack)
#     for i in 1:length(tt.branches)
#         tt.branches[i].endpoint += i
#     end
# end

# @time fill(Branch(0,0),1000000)
# @time my_tt = TrainTrack(fill(Branch(0,0),1000000))
# @time fill1(my_tt)

# function fill2(tt::TrainTrack2)
#     for i in 1:length(tt.branch_endpoints)
#         if i%2 == 0
#             tt.branch_endpoints[i] += i
#         else
#             tt.branch_startpoints[i] += i
#         end
#     end
# end

# @time fill(0,1000000); fill(0,1000000)
# @time my_tt2 = TrainTrack2(fill(0,1000000), fill(0,1000000))
# @time fill2(my_tt2)

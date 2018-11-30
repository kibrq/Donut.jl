export TrainTrack, branch_endpoint, numoutgoing_branches, outgoing_branches, istwisted, switches, branches, numbranches, switchvalence, istrivalent, is_branch_large, is_branch_small_foldable, tt_gluinglist, isswitch, isbranch, extremal_branch, next_branch, copy

using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD, START, END
import Base.copy
using Donut.Utils: otherside

mutable struct TrainTrack
    branch_endpoints::Array{Int, 2}
    istwisted::Array{Bool, 1}
    branch_neighbors::Array{Int, 3}
    extremal_outgoing_branches::Array{Int, 3}

    function TrainTrack(a, b, c, d)
        new(a, b, c, d)
    end

    function TrainTrack(gluinglist::Array{Array{Int,1},1},
                        twisted_branches::Array{Int,1}=Int[])
        if length(gluinglist) % 2 == 1
            error("The length of the gluing list must be even.")
        end

        for ls in gluinglist
            if length(ls) == 0
                error("Each array should be non-empty")
            end
        end

        all_branches = sort(collect(Iterators.flatten(gluinglist)))
        if length(all_branches) % 2 != 0
            error("The total number of indices in the input should be even.")
        end

        halflen = div(length(all_branches), 2)
        for i in 1:halflen
            if all_branches[i] != -all_branches[2*halflen - i + 1]
                error("The negative of each index must also appear in the list.")
            end
        end
        for i in 2:halflen+1
            if all_branches[i] == all_branches[i-1]
                error("Every index should appear in the gluing list at most once.")
            end
        end

        branch_arr_size = maximum(maximum(abs(x) for x in y) for y in gluinglist)
        switch_arr_size = div(length(gluinglist), 2)

        branch_endpoints = zeros(Int, 2, branch_arr_size)
        istwisted = zeros(Bool, branch_arr_size)
        branch_neighbors = zeros(Int, 2, 2, branch_arr_size)
        extremal_outgoing_branches = zeros(Int, 2, 2, switch_arr_size)

        for i in twisted_branches
            istwisted[i] = true
        end

        for sw in 1:switch_arr_size
            for direction in (FORWARD, BACKWARD)
                ls = gluinglist[2*sw - 2 + direction]
                extremal_outgoing_branches[direction, LEFT, sw] = ls[1]

                prev_branch = 0
                sgn = direction == FORWARD ? 1 : -1
                for br in ls
                    branch_endpoints[br > 0 ? START : END, abs(br)] = sgn*sw
                    branch_neighbors[br > 0 ? FORWARD : BACKWARD, LEFT, abs(br)] = prev_branch
                    if prev_branch != 0
                        branch_neighbors[prev_branch > 0 ? FORWARD : BACKWARD, RIGHT, abs(prev_branch)] = br
                    end
                    prev_branch = br
                end
                extremal_outgoing_branches[direction, RIGHT, sw] = ls[end]
            end
        end

        new(branch_endpoints, istwisted, branch_neighbors, extremal_outgoing_branches)
    end
end

function copy(tt::TrainTrack)
    TrainTrack(copy(tt.branch_endpoints), copy(tt.istwisted), copy(tt.branch_neighbors), copy(tt.extremal_outgoing_branches))
end

function extremal_branch(tt::TrainTrack, sw::Int, side::Int=LEFT)
    return tt.extremal_outgoing_branches[sw > 0 ? FORWARD : BACKWARD, side, abs(sw)]
end

function _set_extremal_branch!(tt::TrainTrack, sw::Int, side::Int, br::Int)
    tt.extremal_outgoing_branches[sw > 0 ? FORWARD : BACKWARD, side, abs(sw)] = br
end

function next_branch(tt::TrainTrack, br::Int, side::Int=LEFT)
    return tt.branch_neighbors[br > 0 ? FORWARD : BACKWARD, side, abs(br)]
end

function _set_next_branch!(tt::TrainTrack, br::Int, side::Int, br2::Int)
    tt.branch_neighbors[br > 0 ? FORWARD : BACKWARD, side, abs(br)] = br2
end

struct BranchIterator
    tt::TrainTrack
    start_br::Int
    end_br::Int
    start_side::Int
end

BranchIterator(a, b, c) = BranchIterator(a, b, c, LEFT)
BranchIterator(a, b) = BranchIterator(a, b, b, LEFT)


function Base.iterate(iter::BranchIterator, state::Int=0)
    # println(iter.start_br)
    # println(iter.end_br)
    # println(iter.start_side)
    # println(state)
    # println()
    if state == 0
        current_br = iter.start_br
    else 
        prev_br = state
        if prev_br == iter.end_br
            return nothing
        end
        current_br = next_branch(iter.tt, prev_br, otherside(iter.start_side))
    end
    state = current_br
    @assert state != 0
    return (current_br, state)
end

function Base.length(iter::BranchIterator)
    count = 0
    for br in iter
        count += 1
    end
    return count
end

function verify(iter::BranchIterator)
    for br in iter
    end
    # if the iterator is not valid, then an assertion will fail during the iteration.
end

branch_endpoint(tt::TrainTrack, branch::Int) = tt.branch_endpoints[branch > 0 ? END : START, abs(branch)]

"""
WARNING: It leaves the TrainTrack object in an inconsistent state.
"""
_setendpoint!(tt::TrainTrack, branch::Int, switch::Int) =
    tt.branch_endpoints[branch > 0 ? END : START, abs(branch)] = switch


function outgoing_branches(tt::TrainTrack, switch::Int, start_side::Int=LEFT)
    return BranchIterator(tt, extremal_branch(tt, switch, start_side),
    extremal_branch(tt, switch, otherside(start_side)), start_side)
end

numoutgoing_branches(tt::TrainTrack, switch::Int) = length(outgoing_branches(tt, switch))


istwisted(tt::TrainTrack, branch::Int) = tt.istwisted[abs(branch)]

_set_twisted!(tt::TrainTrack, branch::Int, istwisted::Bool) = 
    (tt.istwisted[abs(branch)] = istwisted)

twist_branch!(tt::TrainTrack, branch::Int) = 
    (tt.istwisted[abs(branch)] = !tt.istwisted[abs(branch)])

isswitch(tt::TrainTrack, sw::Int) = 1 <= abs(sw) <= size(tt.extremal_outgoing_branches)[3] && tt.extremal_outgoing_branches[FORWARD, LEFT, abs(sw)] != 0

switches(tt::TrainTrack) = (i for i in 1:size(tt.extremal_outgoing_branches)[3] if tt.extremal_outgoing_branches[FORWARD, LEFT, i] != 0)

""" Return a switch number with is suitable as a new switch.

The new switch won't be connected to any branches just yet.
If necessary, new space is allocated.
"""
function _find_new_switch_number!(tt::TrainTrack)
    for i in eachindex(size(tt.extremal_outgoing_branches)[3])  
        if tt.extremal_outgoing_branches[FORWARD, LEFT, i] == 0 && tt.extremal_outgoing_branches[FORWARD, RIGHT, i] == 0
            return i
        end
    end
    tt.extremal_outgoing_branches = cat(tt.extremal_outgoing_branches, zeros(Int, 2, 2), dims=3)
    return size(tt.extremal_outgoing_branches)[3]
end

isbranch(tt::TrainTrack, br::Int) = 1 <= abs(br) <= size(tt.branch_endpoints)[2] && tt.branch_endpoints[START, abs(br)] != 0

branches(tt::TrainTrack) = (i for i in 1:size(tt.branch_endpoints)[2] if tt.branch_endpoints[START, i] != 0)

function numbranches(tt::TrainTrack)
    count = 0
    for br in branches(tt)
        count += 1
    end
    return count
end

"""
Return a positive integer suitable for an additional branch.

The new branch won't be connected to any switches just yet. If
necessary, new space is allocated.
"""
function _find_new_branch_number!(tt::TrainTrack)
    for i in eachindex(size(tt.branch_endpoints)[2])    
        if tt.branch_endpoints[START, i] == 0
            return i
        end
    end
    tt.branch_endpoints = cat(tt.branch_endpoints, zeros(Int, 2), dims=2)
    push!(tt.istwisted, 0)
    tt.branch_neighbors = cat(tt.branch_neighbors, zeros(Int, 2, 2), dims=3)
    return length(tt.istwisted)
end

switchvalence(tt::TrainTrack, switch::Int) = numoutgoing_branches(tt, switch) + numoutgoing_branches(tt, -switch)

twisted_branches(tt::TrainTrack) = (br for br in branches(tt) if istwisted(tt, br))

istrivalent(tt::TrainTrack) = all(switchvalence(tt, sw) == 3 for sw in switches(tt))


function is_branch_large(tt::TrainTrack, branch::Int)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    numoutgoing_branches(tt, end_sw) == 1 && numoutgoing_branches(tt, start_sw) == 1
end


function tt_gluinglist(tt::TrainTrack)
    [collect(collect(outgoing_branches(tt, sg*sw))) for sw in switches(tt) for sg in (1, -1)]
end

function Base.show(io::IO, tt::TrainTrack)
    print(io, "Traintrack with gluing list ", tt_gluinglist(tt))
    twbr = collect(twisted_branches(tt))
    if length(twbr) > 0
        println()
        print(io, "Twisted branches: ", twbr)
    end
end


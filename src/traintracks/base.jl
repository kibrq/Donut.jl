


mutable struct PlainTrainTrack
    branch_endpoints::Array{Int16, 2}
    istwisted::Array{Bool, 1}
    branch_neighbors::Array{Int16, 3}
    extremal_outgoing_branches::Array{Int16, 3}

    function PlainTrainTrack(a, b, c, d)
        new(a, b, c, d)
    end

    function PlainTrainTrack(gluinglist::Vector{<:Vector{<:Integer}},
                        twisted_branches::Vector{<:Integer}=Int[])
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

        branch_endpoints = zeros(Int16, 2, branch_arr_size)
        istwisted = zeros(Bool, branch_arr_size)
        branch_neighbors = zeros(Int16, 2, 2, branch_arr_size)
        extremal_outgoing_branches = zeros(Int16, 2, 2, switch_arr_size)

        for i in twisted_branches
            istwisted[i] = true
        end


        for sw in 1:switch_arr_size
            for direction in (FORWARD, BACKWARD)
                ls = gluinglist[2*sw - 2 + Int(direction)]
                extremal_outgoing_branches[Int(direction), Int(LEFT), sw] = ls[1]

                prev_branch = 0
                sgn = direction == FORWARD ? 1 : -1
                for br in ls
                    branch_endpoints[br > 0 ? Int(BACKWARD) : Int(FORWARD), abs(br)] = sgn*sw
                    branch_neighbors[br > 0 ? Int(FORWARD) : Int(BACKWARD), 
                        Int(LEFT), abs(br)] = prev_branch
                    if prev_branch != 0
                        branch_neighbors[Int(prev_branch > 0 ? FORWARD : BACKWARD), 
                            Int(RIGHT), abs(prev_branch)] = br
                    end
                    prev_branch = br
                end
                extremal_outgoing_branches[Int(direction), Int(RIGHT), sw] = ls[end]
            end
        end

        new(branch_endpoints, istwisted, branch_neighbors, extremal_outgoing_branches)
    end
end

function Base.copy(tt::PlainTrainTrack)
    PlainTrainTrack(copy(tt.branch_endpoints), copy(tt.istwisted), copy(tt.branch_neighbors), copy(tt.extremal_outgoing_branches))
end

function extremal_branch(tt::PlainTrainTrack, sw::Integer, side::Side=LEFT)
    return tt.extremal_outgoing_branches[Int(sw > 0 ? FORWARD : BACKWARD), Int(side), abs(sw)]
end

function _set_extremal_branch!(tt::PlainTrainTrack, sw::Integer, side::Side, br::Integer)
    tt.extremal_outgoing_branches[Int(sw > 0 ? FORWARD : BACKWARD), Int(side), abs(sw)] = br
end

function next_branch(tt::PlainTrainTrack, br::Integer, side::Side=LEFT)
    return tt.branch_neighbors[Int(br > 0 ? FORWARD : BACKWARD), Int(side), abs(br)]
end

function _set_next_branch!(tt::PlainTrainTrack, br::Integer, side::Side, br2::Integer)
    tt.branch_neighbors[Int(br > 0 ? FORWARD : BACKWARD), Int(side), abs(br)] = br2
end

struct BranchIterator
    tt::PlainTrainTrack
    start_br::Int16
    end_br::Int16
    start_side::Side
end

BranchIterator(a, b, c) = BranchIterator(a, b, c, LEFT)
BranchIterator(a, b) = BranchIterator(a, b, b, LEFT)


function Base.iterate(iter::BranchIterator, state::Integer=0)
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

branch_endpoint(tt::PlainTrainTrack, branch::Integer) = 
    tt.branch_endpoints[Int(branch > 0 ? FORWARD : BACKWARD), abs(branch)]

"""
WARNING: It leaves the PlainTrainTrack object in an inconsistent state.
"""
_setendpoint!(tt::PlainTrainTrack, branch::Integer, switch::Integer) =
    tt.branch_endpoints[Int(branch > 0 ? FORWARD : BACKWARD), abs(branch)] = switch


function outgoing_branches(tt::PlainTrainTrack, switch::Integer, start_side::Side=LEFT)
    return BranchIterator(tt, extremal_branch(tt, switch, start_side),
    extremal_branch(tt, switch, otherside(start_side)), start_side)
end

numoutgoing_branches(tt::PlainTrainTrack, switch::Integer) = length(outgoing_branches(tt, switch))


istwisted(tt::PlainTrainTrack, branch::Integer) = tt.istwisted[abs(branch)]

_set_twisted!(tt::PlainTrainTrack, branch::Integer, istwisted::Bool) = 
    (tt.istwisted[abs(branch)] = istwisted)

twist_branch!(tt::PlainTrainTrack, branch::Integer) = 
    (tt.istwisted[abs(branch)] = !tt.istwisted[abs(branch)])



isswitch(tt::PlainTrainTrack, sw::Integer) = 1 <= abs(sw) <= size(tt.extremal_outgoing_branches)[3] && 
    tt.extremal_outgoing_branches[Int(FORWARD), Int(LEFT), abs(sw)] != 0

switches(tt::PlainTrainTrack) = (i for i in 1:size(tt.extremal_outgoing_branches)[3] 
    if tt.extremal_outgoing_branches[Int(FORWARD), Int(LEFT), i] != 0)

""" Return a switch number with is suitable as a new switch.

The new switch won't be connected to any branches just yet.
If necessary, new space is allocated.
"""
function _find_new_switch_number!(tt::PlainTrainTrack)
    for i in eachindex(size(tt.extremal_outgoing_branches)[3])  
        if tt.extremal_outgoing_branches[Int(FORWARD), Int(LEFT), i] == 0 && 
            tt.extremal_outgoing_branches[Int(FORWARD), Int(RIGHT), i] == 0
            return i
        end
    end
    tt.extremal_outgoing_branches = cat(tt.extremal_outgoing_branches, zeros(Int16, 2, 2), dims=3)
    return size(tt.extremal_outgoing_branches)[3]
end

isbranch(tt::PlainTrainTrack, br::Integer) = 1 <= abs(br) <= size(tt.branch_endpoints)[2] && 
    tt.branch_endpoints[Int(BACKWARD), abs(br)] != 0

branches(tt::PlainTrainTrack) = (i for i in 1:size(tt.branch_endpoints)[2] if tt.branch_endpoints[Int(BACKWARD), i] != 0)

function numbranches(tt::PlainTrainTrack)
    count = 0
    for br in branches(tt)
        count += 1
    end
    return count
end

function numswitches(tt::PlainTrainTrack)
    count = 0
    for br in switches(tt)
        count += 1
    end
    return count
end

function numcusps(tt::PlainTrainTrack)
    count = 0
    for br in branches(tt)
        for sgn in (-1, 1)
            if next_branch(tt, sgn*br, RIGHT) != 0
                count += 1
            end
        end
    end
    count
end

"""
Return a positive integer suitable for an additional branch.

The new branch won't be connected to any switches just yet. If
necessary, new space is allocated.
"""
function _find_new_branch_number!(tt::PlainTrainTrack)
    for i in eachindex(size(tt.branch_endpoints)[2])    
        if tt.branch_endpoints[Integer(BACKWARD), i] == 0
            return i
        end
    end
    tt.branch_endpoints = cat(tt.branch_endpoints, zeros(Int16, 2), dims=2)
    push!(tt.istwisted, 0)
    tt.branch_neighbors = cat(tt.branch_neighbors, zeros(Int16, 2, 2), dims=3)
    return length(tt.istwisted)
end

switchvalence(tt::PlainTrainTrack, switch::Integer) = numoutgoing_branches(tt, switch) + numoutgoing_branches(tt, -switch)

twisted_branches(tt::PlainTrainTrack) = (br for br in branches(tt) if istwisted(tt, br))

istrivalent(tt::PlainTrainTrack) = all(switchvalence(tt, sw) == 3 for sw in switches(tt))


function is_branch_large(tt::PlainTrainTrack, branch::Integer)
    start_sw = branch_endpoint(tt, -branch)
    end_sw = branch_endpoint(tt, branch)
    numoutgoing_branches(tt, end_sw) == 1 && numoutgoing_branches(tt, start_sw) == 1
end


function tt_gluinglist(tt::PlainTrainTrack)
    [collect(collect(outgoing_branches(tt, sg*sw))) for sw in switches(tt) for sg in (1, -1)]
end

function Base.show(io::IO, tt::PlainTrainTrack)
    print(io, "Traintrack with gluing list ", tt_gluinglist(tt))
    twbr = collect(twisted_branches(tt))
    if length(twbr) > 0
        println()
        print(io, "Twisted branches: ", twbr)
    end
end


"""Return the total extra valence (above 3) of the switches."""
function _extra_valence(tt::PlainTrainTrack)
    return sum(max(switchvalence(tt, sw)-3,0) for sw in switches(tt))
end

"""Return the number of switches the train track can have if made
trivalent."""
numswitches_if_made_trivalent(tt::PlainTrainTrack) = numswitches(tt) + _extra_valence(tt)

"""Return the number of branches the train track can have if made
trivalent."""
numbranches_if_made_trivalent(tt::PlainTrainTrack) = numbranches(tt) + _extra_valence(tt)

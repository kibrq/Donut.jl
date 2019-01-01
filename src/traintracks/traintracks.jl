


export DecoratedTrainTrack, branch_endpoint, numoutgoing_branches, outgoing_branches, istwisted, 
    switches, branches, isbranch, isswitch, is_branch_large, 
    switchvalence, istrivalent, extremal_branch, 
    cusp_to_branch, branch_to_cusp, cusp_to_switch, cusps,
    next_branch, numcusps, numswitches, numbranches, add_measure!, branchmeasure,
    apply_tt_operation!


mutable struct DecoratedTrainTrack
    tt::TrainTrack
    cusphandler::Union{CuspHandler, Nothing}
    measure::Union{Measure, Nothing}
    # Other things we could add: transverse measure, oriented measure for oriented curves  
    
    DecoratedTrainTrack(a, b, c) = new(a, b, c)

    function DecoratedTrainTrack(
        gluinglist::Vector{<:Vector{<:Integer}};
        twisted_branches::Vector{<:Integer}=Int[],
        measure::Union{Vector{T}, Nothing}=nothing,
        keep_trackof_cusps::Bool=false
    ) where T
        tt = TrainTrack(gluinglist, twisted_branches)
        ch = keep_trackof_cusps ? CuspHandler(tt) : nothing
        if measure != nothing
            measure  = Measure{T}(tt, measure)
        end
        new(tt, ch, measure)
    end
end

# -------------------------------------------
# Extend the basic functionality of train tracks from base.jl
# -------------------------------------------

copy(a::Nothing) = nothing

function copy(tt::DecoratedTrainTrack)
    DecoratedTrainTrack(copy(tt.tt), copy(tt.cusphandler), copy(tt.measure))
end

function extremal_branch(dtt::DecoratedTrainTrack, sw::Integer, side::Side=LEFT)
    extremal_branch(dtt.tt, sw, side)
end

function next_branch(dtt::DecoratedTrainTrack, br::Integer, side::Side=LEFT)
    next_branch(dtt.tt, br, side)
end

branch_endpoint(dtt::DecoratedTrainTrack, branch::Integer) = branch_endpoint(dtt.tt, branch)

function outgoing_branches(dtt::DecoratedTrainTrack, switch::Integer, start_side::Side=LEFT)
    outgoing_branches(dtt.tt, switch, start_side)
end

numoutgoing_branches(dtt::DecoratedTrainTrack, switch::Integer) = numoutgoing_branches(dtt.tt, switch)
istwisted(dtt::DecoratedTrainTrack, branch::Integer) = istwisted(dtt.tt, branch)
switches(dtt::DecoratedTrainTrack) = switches(dtt.tt)
branches(dtt::DecoratedTrainTrack) = branches(dtt.tt)
numbranches(dtt::DecoratedTrainTrack) = numbranches(dtt.tt)
numswitches(dtt::DecoratedTrainTrack) = numswitches(dtt.tt)
numcusps(dtt::DecoratedTrainTrack) = numcusps(dtt.tt)
switchvalence(dtt::DecoratedTrainTrack, sw::Integer) = switchvalence(dtt.tt, sw)
istrivalent(dtt::DecoratedTrainTrack) = istrivalent(dtt.tt)

branchmeasure(dtt::DecoratedTrainTrack, br::Integer) = branchmeasure(dtt.measure, br)
outgoingmeasure(dtt::DecoratedTrainTrack, sw::Integer) = outgoingmeasure(dtt.tt, dtt.measure, sw)

cusp_to_branch(dtt::DecoratedTrainTrack, cusp::Integer, side::Side) = 
    cusp_to_branch(dtt.cusphandler, cusp, side)
branch_to_cusp(dtt::DecoratedTrainTrack, br::Integer, side::Side) =
    branch_to_cusp(dtt.cusphandler, br, side)
cusp_to_switch(dtt::DecoratedTrainTrack, cusp::Integer) = cusp_to_switch(dtt.tt, dtt.cusphandler, cusp)
cusps(dtt::DecoratedTrainTrack) = cusps(dtt.cusphandler)
isbranch(dtt::DecoratedTrainTrack, br::Integer) = isbranch(dtt.tt, br) 
isswitch(dtt::DecoratedTrainTrack, sw::Integer) = isswitch(dtt.tt, sw) 
is_branch_large(dtt::DecoratedTrainTrack, br::Integer) = is_branch_large(dtt.tt, br)


function Base.show(io::IO, dtt::DecoratedTrainTrack)
    print(io, dtt.tt)
    if hasmeasure(dtt)
        println(io, "Measure: ", dtt.measure)
    end
end

# -------------------------------------------


hasmeasure(dtt::DecoratedTrainTrack) = dtt.measure != nothing
hascusphandler(dtt::DecoratedTrainTrack) = dtt.cusphandler != nothing

function add_cusphandler!(dtt::DecoratedTrainTrack)
    if dtt.cusphandler != nothing
        error("The train track already has a cusphandler stored.")
    end
    dtt.cusphandler = CuspHandler(dtt.tt)
    return dtt.cusphandler
end

function add_measure!(dtt::DecoratedTrainTrack, measure::Vector{T}) where T
    if dtt.measure != nothing
        error("The train track already has a measure.")
    end
    measure = Measure{T}(measure)
    dtt.measure = measure
end


function apply_tt_operation!(dtt::DecoratedTrainTrack, op::ElementaryTTOperation)
    added_or_deleted_sw = apply_tt_operation!(dtt.tt, op)
    if hasmeasure(dtt)
        updatemeasure_afterop!(dtt.tt, dtt.measure, op, added_or_deleted_sw)
    end
    if hascusphandler(dtt)
        updatecusps_afterop!(dtt.tt, dtt.cusphandler, op, added_or_deleted_sw)
    end
    added_or_deleted_sw
end

function apply_tt_operation!(dtt::DecoratedTrainTrack, op::TTOperation)
    added_or_deleted_sw = 0
    for elem_op in convert_to_elementaryops(dtt.tt, op)
        added_or_deleted_sw = apply_tt_operation!(dtt, elem_op)
    end
    added_or_deleted_sw
end



# #--------------------------------------
# # Convenience functions, one could just as well use apply_tt_operation! directly

# function peel!(dtt::DecoratedTrainTrack, sw::Integer, side::Side)
#     apply_tt_operation!(dtt, peel_op(sw, side))
# end

# function fold!(dtt::DecoratedTrainTrack, fold_onto_br::Integer, folded_br_side::Side)
#     apply_tt_operation!(dtt, fold_op(fold_onto_br, folded_br_side))
# end

# function pullout_branches!(dtt::DecoratedTrainTrack, iter::BranchIterator)
#     op = pullout_branches_op(iter.start_br, iter.end_br, iter.start_side)
#     apply_tt_operation!(dtt, op)
# end

# function collapse_branch!(dtt::DecoratedTrainTrack, br::Integer)
#     apply_tt_operation!(dtt, collapse_branch_op(br))
# end

# function renamebranch!(dtt::DecoratedTrainTrack, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(dtt, renaming_branch_op(oldlabel, newlabel))
# end

# function renameswitch!(dtt::DecoratedTrainTrack, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(dtt, renaming_switch_op(oldlabel, newlabel))
# end



#--------------------------------------



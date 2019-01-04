





mutable struct TrainTrack
    tt::PlainTrainTrack
    cusphandler::Union{CuspHandler, Nothing}
    measure::Union{Measure, Nothing}
    # Other things we could add: transverse measure, oriented measure for oriented curves  
    
    TrainTrack(a, b, c) = new(a, b, c)

    function TrainTrack(
        gluinglist::Vector{<:Vector{<:Integer}};
        twisted_branches::Vector{<:Integer}=Int[],
        measure::Union{Vector{T}, Nothing}=nothing,
        keep_trackof_cusps::Bool=false
    ) where T
        tt = PlainTrainTrack(gluinglist, twisted_branches)
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

Base.copy(a::Nothing) = nothing

function Base.copy(tt::TrainTrack)
    TrainTrack(copy(tt.tt), copy(tt.cusphandler), copy(tt.measure))
end

function extremal_branch(dtt::TrainTrack, sw::Integer, side::Side=LEFT)
    extremal_branch(dtt.tt, sw, side)
end

function next_branch(dtt::TrainTrack, br::Integer, side::Side=LEFT)
    next_branch(dtt.tt, br, side)
end

branch_endpoint(dtt::TrainTrack, branch::Integer) = branch_endpoint(dtt.tt, branch)

function outgoing_branches(dtt::TrainTrack, switch::Integer, start_side::Side=LEFT)
    outgoing_branches(dtt.tt, switch, start_side)
end

numoutgoing_branches(dtt::TrainTrack, switch::Integer) = numoutgoing_branches(dtt.tt, switch)
istwisted(dtt::TrainTrack, branch::Integer) = istwisted(dtt.tt, branch)
switches(dtt::TrainTrack) = switches(dtt.tt)
branches(dtt::TrainTrack) = branches(dtt.tt)
numbranches(dtt::TrainTrack) = numbranches(dtt.tt)
numswitches(dtt::TrainTrack) = numswitches(dtt.tt)
numcusps(dtt::TrainTrack) = numcusps(dtt.tt)
switchvalence(dtt::TrainTrack, sw::Integer) = switchvalence(dtt.tt, sw)
istrivalent(dtt::TrainTrack) = istrivalent(dtt.tt)

branchmeasure(dtt::TrainTrack, br::Integer) = branchmeasure(dtt.measure, br)
outgoingmeasure(dtt::TrainTrack, sw::Integer) = outgoingmeasure(dtt.tt, dtt.measure, sw)

cusp_to_branch(dtt::TrainTrack, cusp::Integer, side::Side) = 
    cusp_to_branch(dtt.cusphandler, cusp, side)
branch_to_cusp(dtt::TrainTrack, br::Integer, side::Side) =
    branch_to_cusp(dtt.cusphandler, br, side)
cusp_to_switch(dtt::TrainTrack, cusp::Integer) = cusp_to_switch(dtt.tt, dtt.cusphandler, cusp)
cusps(dtt::TrainTrack) = cusps(dtt.cusphandler)
isbranch(dtt::TrainTrack, br::Integer) = isbranch(dtt.tt, br) 
isswitch(dtt::TrainTrack, sw::Integer) = isswitch(dtt.tt, sw) 
is_branch_large(dtt::TrainTrack, br::Integer) = is_branch_large(dtt.tt, br)


function Base.show(io::IO, dtt::TrainTrack)
    print(io, dtt.tt)
    if hasmeasure(dtt)
        println(io, "Measure: ", dtt.measure)
    end
end

# -------------------------------------------


hasmeasure(dtt::TrainTrack) = dtt.measure != nothing
hascusphandler(dtt::TrainTrack) = dtt.cusphandler != nothing

function add_cusphandler!(dtt::TrainTrack)
    if dtt.cusphandler != nothing
        error("The train track already has a cusphandler stored.")
    end
    dtt.cusphandler = CuspHandler(dtt.tt)
    return dtt.cusphandler
end

function add_measure!(dtt::TrainTrack, measure::Vector{T}) where T
    if dtt.measure != nothing
        error("The train track already has a measure.")
    end
    measure = Measure{T}(measure)
    dtt.measure = measure
end


function apply_tt_operation!(dtt::TrainTrack, op::ElementaryTTOperation)
    added_or_deleted_sw = apply_tt_operation!(dtt.tt, op)
    if hasmeasure(dtt)
        updatemeasure_afterop!(dtt.tt, dtt.measure, op, added_or_deleted_sw)
    end
    if hascusphandler(dtt)
        updatecusps_afterop!(dtt.tt, dtt.cusphandler, op, added_or_deleted_sw)
    end
    added_or_deleted_sw
end

function apply_tt_operation!(dtt::TrainTrack, op::TTOperation)
    added_or_deleted_sw = 0
    for elem_op in convert_to_elementaryops(dtt.tt, op)
        added_or_deleted_sw = apply_tt_operation!(dtt, elem_op)
    end
    added_or_deleted_sw
end



# #--------------------------------------
# # Convenience functions, one could just as well use apply_tt_operation! directly

# function peel!(dtt::TrainTrack, sw::Integer, side::Side)
#     apply_tt_operation!(dtt, peel_op(sw, side))
# end

# function fold!(dtt::TrainTrack, fold_onto_br::Integer, folded_br_side::Side)
#     apply_tt_operation!(dtt, fold_op(fold_onto_br, folded_br_side))
# end

# function pullout_branches!(dtt::TrainTrack, iter::BranchIterator)
#     op = pullout_branches_op(iter.start_br, iter.end_br, iter.start_side)
#     apply_tt_operation!(dtt, op)
# end

# function collapse_branch!(dtt::TrainTrack, br::Integer)
#     apply_tt_operation!(dtt, collapse_branch_op(br))
# end

# function renamebranch!(dtt::TrainTrack, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(dtt, renaming_branch_op(oldlabel, newlabel))
# end

# function renameswitch!(dtt::TrainTrack, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(dtt, renaming_switch_op(oldlabel, newlabel))
# end



#--------------------------------------



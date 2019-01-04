





"""
Notexisting branches should have 0 in the corresponding index. This assumption is used by some utility functions, e.g. updating the measure when pulling apart.
"""
struct Measure{T}
    values::Array{T, 1}

    function Measure{T}(values::Vector{T}) where {T}
        new(values)
    end

    function Measure{T}(tt::PlainTrainTrack, valuearray::Array{T, 1}, allownegatives::Bool=false) where {T}
        if length(valuearray) != numbranches(tt)
            error("The length of the values array ($(valuearray)) should equal the number of branches ($(numbranches(tt))")
        end
        if !allownegatives
            for value in valuearray
                if value < 0
                    error("The measure should be nonnegative.")
                end
            end
        end
        branchiter = branches(tt)
        maxbranch_number = maximum(branchiter)
        values = zeros(T, maxbranch_number)

        i = 1
        for br in branchiter
            values[br] = valuearray[i]
            i += 1
        end

        for sw in switches(tt)
            sums = [sum([values[abs(br)] for br in outgoing_branches(tt, sign*sw)]) for sign in (-1, 1)]
            if sums[1] != sums[2]
                error("The switch condition is not satisfied at switch $(sw).")
            end
        end
        new(values)
    end 
end

function Base.copy(measure::Measure{T}) where {T} 
    Measure{T}(copy(measure.values))
end

function zeromeasure(tt::PlainTrainTrack, type)
    Measure{type}(tt, zeros(type, numbranches(tt)))
end


function branchmeasure(measure::Measure, branchindex::Integer)
    measure.values[abs(branchindex)]
end

function outgoingmeasure(tt::PlainTrainTrack, measure::Measure, switch::Integer)
    sum(branchmeasure(measure, br) for br in outgoing_branches(tt, switch))
end

"""
Can mess up switch conditions.
"""
function _setmeasure!(measure::Measure, branchindex::Integer, newvalue)
    measure.values[abs(branchindex)] = newvalue 
end

"""
Allocate a larger array internally and fill it with zeros.
"""
function _allocatemore!(measure::Measure, newlength::Integer)
    len = length(measure.values)
    resize!(measure.values, newlength)
    for i in len+1:newlength
        measure.values[i] = 0
    end
end



function updatemeasure_afterop!(tt_afterop::PlainTrainTrack,
    measure::Measure, op::PulloutBranches, new_sw::Integer)
    new_br = new_branch_after_pullout(tt_afterop, new_sw)
    if abs(new_br) > length(measure.values)
        _allocatemore!(measure, abs(new_br))
    end
    newvalue = outgoingmeasure(tt_afterop, measure, new_sw)
    # println("*****************************************************************************")
    # println("br: ", new_br, "new value:", newvalue)
    _setmeasure!(measure, new_br, newvalue)
end


function updatemeasure_afterop!(_::PlainTrainTrack, measure::Measure, op::CollapseBranch,
        _::Integer)
    _setmeasure!(measure, op.br, 0)
end

function updatemeasure_afterop!(_::PlainTrainTrack, measure::Measure, op::DeleteBranch,
        _::Integer)
    if branchmeasure(measure, op.br) != 0
        error("Cannot delete branch $(op.br), because its measure is not zero.")
    end
end

function updatemeasure_afterop!(_::PlainTrainTrack, measure::Measure, op::RenameBranch,
        _::Integer)
    value = branchmeasure(measure, op.oldlabel)
    _setmeasure!(measure, op.oldlabel, 0)
    _setmeasure!(measure, op.newlabel, value)
end

function updatemeasure_afterop!(tt::PlainTrainTrack, measure::Measure, op::Peel,
        _::Integer)        
    peel_off_branch = extremal_branch(tt, -op.sw, otherside(op.side))
    peeled_branch = next_branch(tt, -peel_off_branch, istwisted(tt, peel_off_branch) ? 
        otherside(op.side) : op.side)
    newvalue = branchmeasure(measure, peel_off_branch) - branchmeasure(measure, peeled_branch)
    _setmeasure!(measure, peel_off_branch, newvalue)
end


function updatemeasure_afterop!(tt::PlainTrainTrack, measure::Measure, op::Fold,
        _::Integer)
    sw = branch_endpoint(tt, op.fold_onto_br)
    folded_br = extremal_branch(tt, -sw, istwisted(tt, op.fold_onto_br) ? 
        otherside(op.folded_br_side) : op.folded_br_side)
    newvalue = branchmeasure(measure, op.fold_onto_br) + branchmeasure(measure, folded_br)
    _setmeasure!(measure, op.fold_onto_br, newvalue)
end

function updatemeasure_afterop!(_::PlainTrainTrack, _::Measure, _::RenameSwitch, _::Integer)
end




"""
Consider standing at a switch, looking forward. On each side (LEFT, RIGHT), we can peel either the branch going forward or the branch going backward. This function returns FORWARD or BACKWARD, indicating which branch is peeled according to the measure (the one that has smaller measure).

If the measures are equal, then we need to make sure that we are not peeling from the side where there is only one outgoing branch
"""
function whichside_to_peel(tt::PlainTrainTrack, measure::Measure, switch::Integer, side::Side)
    br1 = extremal_branch(tt, switch, side)
    br2 = extremal_branch(tt, -switch, otherside(side))
    m1 = branchmeasure(measure, br1)
    m2 = branchmeasure(measure, br2)
    if m1 < m2
        return FORWARD
    end
    if m1 > m2
        return BACKWARD
    end

    for sg in (1, -1)
        if remains_recurrent_after_peel(tt, sg*switch, sg == 1 ? side : otherside(side))
            return sg == 1 ? FORWARD : BACKWARD
        end
    end

    @assert false
end



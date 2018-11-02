

module Measures

export Measure, branchmeasure, zeromeasure, outgoingmeasure, copy

using Donut.TrainTracks
import Base.copy

"""
Notexisting branches should have 0 in the corresponding index. This assumption is used by some utility functions, e.g. updating the measure when pulling apart.
"""
struct Measure{T}
    values::Array{T, 1}

    function Measure{T}(values::Vector{T}) where {T}
        new(values)
    end

    function Measure{T}(tt::TrainTrack, valuearray::Array{T, 1}, allownegatives::Bool=false) where {T}
        if length(valuearray) != length(branches(tt))
            error("The length of the values array ($(valuearray)) should equal the number of branches ($(length(branches(tt))))")
        end
        if !allownegatives
            for value in valuearray
                if value < 0
                    error("The measure should be nonnegative.")
                end
            end
        end
        brancharray = branches(tt)
        maxbranch_number = maximum(brancharray)
        values = zeros(T, maxbranch_number)
        for i in eachindex(brancharray)
            br = brancharray[i]
            values[br] = valuearray[i]
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

function copy(measure::Measure{T}) where {T} 
    Measure{T}(copy(measure.values))
end

function zeromeasure(tt::TrainTrack, type)
    Measure{type}(tt, zeros(type, length(branches(tt))))
end


function branchmeasure(measure::Measure, branchindex::Int)
    measure.values[abs(branchindex)]
end

function outgoingmeasure(tt::TrainTrack, measure::Measure, switch::Int)
    sum(branchmeasure(measure, br) for br in outgoing_branches(tt, switch))
end

"""
Can mess up switch conditions.
"""
function _setmeasure!(measure::Measure, branchindex::Int, newvalue)
    measure.values[abs(branchindex)] = newvalue 
end

"""
Allocate a larger array internally and fill it with zeros.
"""
function _allocatemore!(measure::Measure, newlength::Int)
    len = length(measure.values)
    resize!(measure.values, newlength)
    for i in len+1:newlength
        measure.values[i] = 0
    end
end




end # module
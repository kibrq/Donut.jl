

module Measures

export Measure, branchmeasure, zeromeasure

using Donut.TrainTracks

struct Measure{T}
    values::Array{T, 1}

    function Measure{T}(tt::TrainTrack, valuearray::Array{T, 1}, allownegatives::Bool=false) where {T}
        if length(valuearray) != length(branches(tt))
            error("The length of the values array should equal the number of branches")
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



function zeromeasure(tt::TrainTrack, type)
    Measure{type}(tt, zeros(type, length(branches(tt))))
end


function branchmeasure(measure::Measure, branchindex::Int)
    measure.values[abs(branchindex)]
end

"""
Can mess up switch conditions.
"""
function _setmeasure(measure::Measure, branchindex::Int, newvalue)
    measure.values[abs(branchindex)] = newvalue 
end

end
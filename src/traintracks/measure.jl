# export Measure, branchmeasure, zeromeasure


module Measures

using Donut.TrainTracks

struct Measure{T<:Number}
    # values::Array{T, 1}
    values::Dict{Int, T}

    function Measure{T}(tt::TrainTrack, valuedict::Dict{Int, T}, allownegatives::Bool=false) where {T<:Number}
        if !allownegatives
            for value in values(valuedict)
                if value < 0
                    error("The measure should be nonnegative.")
                end
            end
        end
        for sw in switches(tt)
            sums = [sum([valuedict[abs(br)] for br in outgoing_branches(tt, sign*sw)]) for sign in (-1, 1)]
            if sums[1] != sums[2]
                error("The switch condition is not satisfied at switch $(sw).")
            end
        end
        new(valuedict)
    end 

    function Measure{T}(tt::TrainTrack, valuearray::Array{T, 1}) where {T<:Number}
        if length(valuearray) != length(branches(tt))
            error("The length of the values array should equal the number of branches")
        end
        brancharray = branches(tt)
        valuedict = Dict([(brancharray[i], valuearray[i]) for i in eachindex(valuearray)])
        Measure{T}(tt, valuedict)
    end 
end



function zeromeasure(tt::TrainTrack, type)
    # maxbranch_number = maximum(branches(tt))
    Measure{type}(tt, zeros(type, length(branches(tt))))
end


function branchmeasure(measure::Measure, branchindex::Int)
    try 
        return measure.values[abs(branchindex)]
    catch error
        if isa(error, KeyError)
            error("There is no branch with index $(branchindex)")
        else
            throw(error)
        end
    end
end


end

module DehnThurstonCoords

export DehnThurstonCoordinates, intersection_number, twisting_number

using Donut.Pants

struct DehnThurstonCoordinates{T}
    pd::PantsDecomposition
    coords::Vector{Tuple{T, T}}

    function DehnThurstonCoordinates{T}(pd::PantsDecomposition, dtcoords::Vector{Tuple{T,T}}) where {T}
        ipc = innercurves(pd)
        if length(ipc) != length(dtcoords)
            error("The length of the coordinate list $(length(dtcoords)) should agree with the number of inner pants curves $(length(ipc)).")
        end
        for i in eachindex(dtcoords)
            curveindex = ipc[i]
            intersection_number = dtcoords[i][1]
            twisting_number = dtcoords[i][2]
            if intersection_number < 0
                error("The intersection numbers cannot be negative.")
            end
            if intersection_number == 0 && twisting_number < 0
                error("The convention is that when the intersection number is zero, the twisting number is nonnegative.")
            end
        end
        curves = separators(pd)
        len = maximum(curves)
        x = fill((T(0), T(0)), len)
        for i in eachindex(dtcoords)
            x[ipc[i]] = dtcoords[i]
        end
        new(pd, x)
    end
end


function intersection_number(dtcoords::DehnThurstonCoordinates{T}, curveindex::Integer) where {T}
    dtcoords.coords[abs(curveindex)][1]
end

function twisting_number(dtcoords::DehnThurstonCoordinates{T}, curveindex::Integer) where {T}
    dtcoords.coords[abs(curveindex)][2]
end



end
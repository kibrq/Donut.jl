
module DehnThurstonCoords

export DehnThurstonCoordinates, intersection_number, twisting_number

using Donut.Pants

struct DehnThurstonCoordinates{T}
    pd::PantsDecomposition
    coords::Vector{Tuple{T, T}}

    function DehnThurstonCoordinates{T}(pd::PantsDecomposition, dtcoords::Vector{Tuple{T,T}}) where {T}
        ipc = innercurveindices(pd)
        if length(ipc) != length(dtcoords)
            error("The length of the coordinate list $(length(dtcoords)) should agree with the number of inner pants curves $(length(ipc)).")
        end
        for i in eachindex(dtcoords)
            curveindex = ipc[i]
            if istwosided_pantscurve(pd, curveindex)
                # if length(dtcoords[i]) != 2
                #     error("For the two-sided pants curve $(curveindex), exactly two coordinates should be provided instead of $(length(dtcoords[i])).")
                # end
                intersection_number = dtcoords[i][1]
                twisting_number = dtcoords[i][2]
                if intersection_number < 0
                    error("The intersection numbers cannot be negative.")
                end
                if intersection_number == 0 && twisting_number < 0
                    error("The convention is that when the intersection number is zero, the twisting number is nonnegative.")
                end
            elseif isonesided_pantscurve(pd, curveindex)
                if dtcoords[i][2] != 1
                    error("For the one-sided pants curve $(curveindex), the second coordinate should be zero.")
                end
            else
                @assert false
            end
        end
        curves = curveindices(pd)
        len = maximum(curves)
        x = fill((T(0), T(0)), len)
        ipc = innercurveindices(pd)
        for i in eachindex(dtcoords)
            x[ipc[i]] = dtcoords[i]
        end
        new(pd, x)
    end
end


function intersection_number(dtcoords::DehnThurstonCoordinates{T}, curveindex::Int) where {T}
    if !istwosided_pantscurve(dtcoords.pd, curveindex)
        return T(0)
    end
    dtcoords.coords[abs(curveindex)][1]
end

function twisting_number(dtcoords::DehnThurstonCoordinates{T}, curveindex::Int) where {T}
    @assert istwosided_pantscurve(dtcoords.pd, curveindex)
    dtcoords.coords[abs(curveindex)][2]
end



end
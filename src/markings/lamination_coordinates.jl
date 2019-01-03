

export DehnThurstonCoordinates, intersection_number, twisting_number, TriangleCoordinates


struct DehnThurstonCoordinates{T}
    pd::PantsDecomposition
    coords::Vector{Tuple{T, T}}

    function DehnThurstonCoordinates{T}(pd::PantsDecomposition, dtcoords::Vector{Tuple{T,T}}) where {T}
        ipc = innercurves(pd)
        if length(ipc) != length(dtcoords)
            error("The length of the coordinate list $(length(dtcoords)) should agree with the number of inner pants curves $(length(ipc)).")
        end
        for i in eachindex(dtcoords)
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
        # If there are boundary curves, we allocate space for them, too and fill
        # it with (0, 0)
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



struct TriangleCoordinates{T}
    t::Triangulation
    coords::Vector{T}    

    function TriangleCoordinates{T}(t::Triangulation, coords::Vector{T}) where {T}
        if numseparators(t) != length(coords)
            error("The length of the coordinate list $(length(coords)) should "*
            "agree with the number of separators $(numseparators(t)).")
        end
        for i in eachindex(coords)
            intersection_number = coords[i][1]
            if intersection_number < 0
                error("The intersection numbers cannot be negative.")
            end
        end
        new(t, coords)
    end
end

function intersection_number(coords::TriangleCoordinates{T}, separator::Integer) where {T}
    coords.coords[abs(separator)]
end


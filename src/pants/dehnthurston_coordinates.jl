module DTCoordinates

export DehnThurstonCoordinates, dtcoords_of_pantscurve, dtcoords_of_transversal

using Donut.Pants

# TODO: shall we instead use a bigger array instead when the i'th index contains the data of curve i?
struct DehnThurstonCoordinates
    intersection_numbers::Array{Real}
    twisting_numbers::Array{Real}

    function DehnThurstonCoordinates(intersection_numbers, twisting_numbers)
        if length(intersection_numbers) != length(twisting_numbers)
            error("The length of the intersection number array should be the same as the length of the twisting number array.")
        end
        for i in eachindex(intersection_numbers)
            ints = intersection_numbers[i]
            if ints < 0
                error("The intersection number cannot be negative.")
            end
            if ints == 0 && twisting_numbers[i] < 0
                error("The convention is that when the intersection number is zero, the twisting number is nonnegative.")
            end
        end
        new(intersection_numbers, twisting_numbers)
    end
end

# function DehnThurstonCoordinates(intersection_numbers::Array{Int}, twisting_numbers::Array{Int})
# end

function dtcoords_of_pantscurve(pd::PantsDecomposition, pantscurve::Int)
    if !isinner_pantscurve(pd, pantscurve)
        error("There is no inner pants curve of index $(pantscurve).")
    end
    DehnThurstonCoordinates(
        [0 for c in innercurveindices(pd)],
        [abs(pantscurve) != abs(c) ? 0 : 1 for c in innercurveindices(pd)]
    )
    
end

function dtcoords_of_transversal(pd::PantsDecomposition, pantscurve::Int)
    if !isinner_pantscurve(pd, pantscurve)
        error("There is no inner pants curve of index $(pantscurve).")
    end
    leftpant = pant_nextto_pantscurve(pd, pantscurve, LEFT)
    rightpant = pant_nextto_pantscurve(pd, pantscurve, RIGHT)
    # TODO: this might not be correct in the nonorientable case
    numintersections = leftpant == rightpant ? 1 : 2
    DehnThurstonCoordinates(
        [abs(pantscurve) != abs(c) ? 0 : numintersections for c in innercurveindices(pd)],
        [0 for c in innercurveindices(pd)]
    )
end

function dtcoords_random(pd::PantsDecomposition)

end







end

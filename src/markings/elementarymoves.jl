module ElementaryMoves

export apply_move!


using Donut.Pants
using Donut.Pants: _set_regionboundaries!, _setseparatorside!
using Donut.Constants
# function elementarymove_type(pd::PantsDecomposition, curveindex::Int)
#     if isboundary_pantscurve(pd, curveindex)
#         return
#     end
# end



function apply_move!(pd::PantsDecomposition, move::SecondMove)
    leftpant = separator_to_region(pd, move.curveindex, LEFT)
    leftindex = separator_to_bdyindex(pd, move.curveindex, LEFT)
    rightpant = separator_to_region(pd, move.curveindex, RIGHT)
    rightindex = separator_to_bdyindex(pd, move.curveindex, RIGHT)
    @assert leftpant != rightpant

    topleft = region_to_separator(pd, leftpant, nextindex(leftindex))
    bottomleft = region_to_separator(pd, leftpant, previndex(leftindex))
    topright = region_to_separator(pd, rightpant, previndex(rightindex))
    bottomright = region_to_separator(pd, rightpant, nextindex(rightindex))

    # turning the middle curve left by 90 degrees
    # top pant
    toppant = rightpant
    _set_regionboundaries!(pd, toppant, -move.curveindex, topright, topleft)
    _setseparatorside!(pd, move.curveindex, RIGHT, toppant, BdyIndex(1))
    # bottom pant
    bottompant = leftpant
    _set_regionboundaries!(pd, bottompant, move.curveindex, bottomleft, bottomright)
    _setseparatorside!(pd, move.curveindex, LEFT, bottompant, BdyIndex(1))

    _setseparatorside!(pd, topleft, LEFT, toppant, BdyIndex(3))
    _setseparatorside!(pd, topright, LEFT, toppant, BdyIndex(2))
    _setseparatorside!(pd, bottomleft, LEFT, bottompant, BdyIndex(2))
    _setseparatorside!(pd, bottomright, LEFT, bottompant, BdyIndex(3))
end


function apply_move!(pd::PantsDecomposition, move::FirstMove)
    @assert separator_to_region(pd, move.curveindex, LEFT) == 
        separator_to_region(pd, move.curveindex, RIGHT)
    # nothing to do, the gluing list does not change.
    # TODO: shall we permute the boundaries so that the boundary of the torus has index 1?
end




function apply_move!(pd::PantsDecomposition, move::HalfTwist)
    # TODO: "Use direction."
    pantindex = separator_to_region(pd, move.curveindex, move.side)
    bdyindex = separator_to_bdyindex(pd, move.curveindex, move.side)

    boundaries = region_to_separators(pd, pantindex)
    idx2 = nextindex(bdyindex)
    idx3 = previndex(bdyindex)

    curve2 = region_to_separator(pd, pantindex, idx2)
    curve3 = region_to_separator(pd, pantindex, idx3)

    if Int(bdyindex) == 1
        swap_indices = (1, 3, 2)
    elseif Int(bdyindex) == 2
        swap_indices = (3, 2, 1)
    elseif Int(bdyindex) == 3
        swap_indices = (2, 1, 3)
    else
        @assert false
    end
    _set_regionboundaries!(pd, pantindex, boundaries[swap_indices[1]], 
        boundaries[swap_indices[2]], boundaries[swap_indices[3]])
    _setseparatorside!(pd, curve2, LEFT, pantindex, idx3)
    _setseparatorside!(pd, curve3, LEFT, pantindex, idx2)
end

function apply_move!(pd::PantsDecomposition, move::Twist)
    # The gluing list remains the same, nothing to do.
end

end
module ElementaryMoves

export apply_firstmove!, apply_secondmove!, apply_halftwist!, apply_dehntwist!


using Donut.Pants
using Donut.Pants: _setboundarycurves, _setpantscurveside
using Donut.Utils: nextindex, previndex, otherside
using Donut.Constants: LEFT, RIGHT
# function elementarymove_type(pd::PantsDecomposition, curveindex::Int)
#     if isboundary_pantscurve(pd, curveindex)
#         return
#     end
# end



function apply_secondmove!(pd::PantsDecomposition, curveindex::Int)
    leftpant = pant_nextto_pantscurve(pd, curveindex, LEFT)
    leftindex = bdyindex_nextto_pantscurve(pd, curveindex, LEFT)
    rightpant = pant_nextto_pantscurve(pd, curveindex, RIGHT)
    rightindex = bdyindex_nextto_pantscurve(pd, curveindex, RIGHT)
    @assert leftpant != rightpant

    topleft = pantscurve_nextto_pant(pd, leftpant, nextindex(leftindex, 3))
    bottomleft = pantscurve_nextto_pant(pd, leftpant, previndex(leftindex, 3))
    topright = pantscurve_nextto_pant(pd, rightpant, previndex(rightindex, 3))
    bottomright = pantscurve_nextto_pant(pd, rightpant, nextindex(rightindex, 3))

    pant_nextto_pantscurve
    bdyindex_nextto_pantscurve
    pantscurve_nextto_pant

    # turning the middle curve left by 90 degrees
    # top pant
    toppant = rightpant
    _setboundarycurves(pd, toppant, -curveindex, topright, topleft)
    _setpantscurveside(pd, curveindex, RIGHT, toppant, 1)
    # bottom pant
    bottompant = leftpant
    _setboundarycurves(pd, bottompant, curveindex, bottomleft, bottomright)
    _setpantscurveside(pd, curveindex, LEFT, bottompant, 1)

    _setpantscurveside(pd, topleft, LEFT, toppant, 3)
    _setpantscurveside(pd, topright, LEFT, toppant, 2)
    _setpantscurveside(pd, bottomleft, LEFT, bottompant, 2)
    _setpantscurveside(pd, bottomright, LEFT, bottompant, 3)
end


function apply_firstmove!(pd::PantsDecomposition, curveindex::Int)
    @assert pant_nextto_pantscurve(pd, curveindex, LEFT) == pant_nextto_pantscurve(pd, curveindex, RIGHT)
    # nothing to do, the gluing list does not change.
    # TODO: shall we permute the boundaries so that the boundary of the torus has index 1?
end




function apply_halftwist!(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)
    boundaries = pantboundaries(pd, pantindex)
    idx2 = nextindex(bdyindex, 3)
    idx3 = previndex(bdyindex, 3)

    curve2 = pantscurve_nextto_pant(pd, pantindex, idx2)
    curve3 = pantscurve_nextto_pant(pd, pantindex, idx3)

    if bdyindex == 1
        swap_indices = (1, 3, 2)
    elseif bdyindex == 2
        swap_indices = (3, 2, 1)
    elseif bdyindex == 3
        swap_indices = (2, 1, 3)
    else
        @assert false
    end
    _setboundarycurves(pd, pantindex, boundaries[swap_indices[1]], boundaries[swap_indices[2]], boundaries[swap_indices[3]])
    _setpantscurveside(pd, curve2, LEFT, pantindex, idx3)
    _setpantscurveside(pd, curve3, LEFT, pantindex, idx2)
end

function apply_dehntwist!(pd::PantsDecomposition, pantindex::Int, bdyindex::Int, direction::Int)
    # The gluing list remains the same, nothing to do.
end

end



struct Flip
    separator::Int16
end

inverse(move::Flip) = move


abstract type ChangeOfPantsMarking end

struct FirstMove <: ChangeOfPantsMarking
    curveindex::Int16
    isinverse::Bool
end

FirstMove(x) = FirstMove(x, false)
inverse(move::FirstMove) = FirstMove(move.curveindex, !move.isinverse)

struct SecondMove <: ChangeOfPantsMarking
    curveindex::Int16
end

inverse(move::SecondMove) = move

struct HalfTwist <: ChangeOfPantsMarking
    curveindex::Int16
    side::Side
    direction::Side
end

HalfTwist(x, y) = HalfTwist(x, y, RIGHT)
inverse(move::HalfTwist) = HalfTwist(move.curveindex, otherside(move.direction))

struct Twist <: ChangeOfPantsMarking
    curveindex::Int16
    direction::Side
end

Twist(x) = Twist(x, RIGHT)
inverse(move::Twist) = Twist(move.curveindex, otherside(move.direction))


struct PantsDecompositionAutomorphism <: ChangeOfPantsMarking
    pantscurve_map::Array{Int}
end

# EXAMPLE
# pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
# PantsDecompositionAutomorphism([-1, -2, -3]) corresponds to the hyperelliptic involution.
# PantsDecompositionAutomorphism([3, 2, 1]) corresponds to another order 2 involution.



separator(move::Flip) = move.separator
separator(move::SecondMove) = move.curveindex

function flip!(m::TriMarking, move::Union{Flip, SecondMove})
    leftregion = separator_to_region(m, separator(move), LEFT)
    leftbdyindex = separator_to_bdyindex(m, separator(move), LEFT)
    rightregion = separator_to_region(m, separator(move), RIGHT)
    rightbdyindex = separator_to_bdyindex(m, separator(move), RIGHT)
    @assert leftregion != rightregion

    topleft = region_to_separator(m, leftregion, nextindex(leftbdyindex))
    bottomleft = region_to_separator(m, leftregion, previndex(leftbdyindex))
    topright = region_to_separator(m, rightregion, previndex(rightbdyindex))
    bottomright = region_to_separator(m, rightregion, nextindex(rightbdyindex))

    # turning the middle curve left by 90 degrees
    # top pant
    topregion = rightregion
    _set_regionboundaries!(m, topregion, -separator(move), topright, topleft)
    _setseparatorside!(m, separator(move), RIGHT, topregion, BdyIndex(1))
    # bottom pant
    bottomregion = leftregion
    _set_regionboundaries!(m, bottomregion, separator(move), bottomleft, bottomright)
    _setseparatorside!(m, separator(move), LEFT, bottomregion, BdyIndex(1))

    _setseparatorside!(m, topleft, LEFT, topregion, BdyIndex(3))
    _setseparatorside!(m, topright, LEFT, topregion, BdyIndex(2))
    _setseparatorside!(m, bottomleft, LEFT, bottomregion, BdyIndex(2))
    _setseparatorside!(m, bottomright, LEFT, bottomregion, BdyIndex(3))
end

function apply_move!(pd::PantsDecomposition, move::SecondMove)
    flip!(pd, move)
end

function apply_move!(t::Triangulation, move::Flip)
    flip!(t, move)
end

function apply_move!(pd::PantsDecomposition, move::FirstMove)
    # @assert separator_to_region(pd, move.curveindex, LEFT) == 
    #     separator_to_region(pd, move.curveindex, RIGHT)
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


export FirstMove, SecondMove, HalfTwist, Twist, ChangeOfPantsMarking


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


# function Base.show(io::IO, pmc::ChangeOfPantsMarking)



abstract type ChangeOfPantsMarking end

struct FirstMove <: ChangeOfPantsMarking
    curveindex::Int
    inverse::Bool
end

FirstMove(x) = FirstMove(x, false)
inverse(move::FirstMove) = FirstMove(move.curveindex, !move.inverse)

struct SecondMove <: ChangeOfPantsMarking
    curveindex::Int
end

inverse(move::SecondMove) = move

struct HalfTwist <: ChangeOfPantsMarking
    curveindex::Int
    power::Int
end

HalfTwist(x) = HalfTwist(x, 1)
inverse(move::HalfTwist) = HalfTwist(move.curveindex, -move.power)

struct Twist <: ChangeOfPantsMarking
    curveindex::Int
    power::Int
end

Twist(x) = Twist(x, 1)
inverse(move::Twist) = Twist(move.curveindex, -move.power)


struct PantsDecompositionAutomorphism <: ChangeOfPantsMarking
    pantscurve_map::Array{Int}
end

# EXAMPLE
# pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
# PantsDecompositionAutomorphism([-1, -2, -3]) corresponds to the hyperelliptic involution.
# PantsDecompositionAutomorphism([3, 2, 1]) corresponds to another order 2 involution.


# function Base.show(io::IO, pmc::ChangeOfPantsMarking)

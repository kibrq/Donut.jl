

# const FIRSTMOVE = 1
# const SECONDMOVE = 2
# const HALFTWIST = 3
# const DEHNTWIST = 4
# const ONESIDED_TO_ONESIDED = 5
# const TWO_ONESIDEDS_TO_TWOSIDED = 6
# const TWOSIDED_TO_TWO_ONESIDEDS = 7


abstract type ChangeOfPantsMarking end

struct FirstMove <: ChangeOfPantsMarking
    curveindex::Int
    inverse::Bool
end

inverse(move::FirstMove) = FirstMove(move.curveindex, !move.inverse)

struct SecondMove <: ChangeOfPantsMarking
    curveindex::Int
end

inverse(move::SecondMove) = move

struct HalfTwist <: ChangeOfPantsMarking
    curveindex::Int
    power::Int
end

inverse(move::HalfTwist) = HalfTwist(move.curveindex, -move.power)

struct Twist <: ChangeOfPantsMarking
    curveindex::Int
    power::Int
end

inverse(move::Twist) = Twist(move.curveindex, -move.power)


struct PantsDecompositionAutomorphism <: ChangeOfPantsMarking
    pantscurve_map::Array{Int}
end

# EXAMPLE
# pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
# PantsDecompositionAutomorphism([-1, -2, -3]) corresponds to the hyperelliptic involution.
# PantsDecompositionAutomorphism([3, 2, 1]) corresponds to another order 2 involution.
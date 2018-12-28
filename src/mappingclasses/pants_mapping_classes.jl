


export pantstwist, transversaltwist, PantsMappingClass

using Donut.Pants
using Donut.Pants: ChangeOfPantsMarking, PantsDecomposition, FirstMove, SecondMove, Twist, HalfTwist, pant_nextto_pantscurve, isequal_strong
using Donut.Laminations: PantsLamination
import Base.*, Base.==, Base.^
import Donut.Pants.inverse
import Donut
import Donut.Pants.copy
import Donut.Laminations.copy
using Donut.Constants: LEFT, RIGHT
using Donut.Laminations
using Donut.PantsAndTrainTracks.PeelFold


abstract type MappingClass end

struct PantsMappingClass <: MappingClass
    pd::PantsDecomposition
    change_of_markings::Vector{ChangeOfPantsMarking}  # applied from right to left
end

function copy(pmc::PantsMappingClass)
    PantsMappingClass(Donut.Pants.copy(pmc.pd), Base.copy(pmc.change_of_markings))
end

function identity_mapping_class(pd::PantsDecomposition)
    PantsMappingClass(pd, ChangeOfPantsMarking[])
end

function pantstwist(pd::PantsDecomposition, curveindex::Int, power::Int=1)
    PantsMappingClass(pd, [Twist(curveindex, -power)])
end

function halftwist(pd::PantsDecomposition, curveindex::Int, power::Int=1)
    # TODO: we should check that the curve is around two boundaries. Input the pd.
    PantsMappingClass(pd, [HalfTwist(curveindex, -power)])
end

function transversaltwist(pd::PantsDecomposition, curveindex::Int, power::Int=1)
    if isfirstmove_curve(pd, curveindex)
        move = FirstMove(curveindex)
    elseif issecondmove_curve(pd, curveindex)
        move = SecondMove(curveindex)
    else
        error("Curve $(curveindex) is not a first or second move curve, so we cannot perform transversaltwist about it.")
    end
    PantsMappingClass(pd, [move, Twist(curveindex, -power), inverse(move)])
end

function precompose!(pmc::PantsMappingClass, compose_by::PantsMappingClass)
    # TODO: replace with weak equality
    # println(pmc.pd.pants)
    # println(pmc.pd.pantscurves)
    # println(compose_by.pd.pants)
    # println(compose_by.pd.pantscurves)
    if !isequal_strong(pmc.pd, compose_by.pd)
        error("Two mapping classes can only be composed when they share the same PantsDecomposition.")
    end
    append!(pmc.change_of_markings, compose_by.change_of_markings)
end

function postcompose!(pmc::PantsMappingClass, compose_by::PantsMappingClass)
    # TODO: replace with weak equality
    if !isequal_strong(pmc.pd, compose_by.pd)
        # println(pmc.pd)
        # println(compose_by.pd)
        error("Two mapping classes can only be composed when they share the same PantsDecomposition.")
    end
    splice!(pmc.change_of_markings, 1:0, compose_by.change_of_markings)
end

function *(pmc1::PantsMappingClass, pmc2::PantsMappingClass)
    pmc = copy(pmc1)
    precompose!(pmc, pmc2)
    pmc
end

function ^(pmc::PantsMappingClass, exp::Int)
    if exp == 0
        return identity_mapping_class(pmc.pd)
    end
    new_arr = Iterators.flatten([pmc.change_of_markings for i in 1:abs(exp)])
    new_pmc = PantsMappingClass(pmc.pd, collect(new_arr))

    if exp > 0
        return new_pmc
    else
        return inv(new_pmc)
    end
end

function apply_change_of_markings_to_lamination!(move::FirstMove, pl::PantsLamination)
    peel_fold_firstmove!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings, move.inverse)
end

function apply_change_of_markings_to_lamination!(move::SecondMove, pl::PantsLamination)
    peel_fold_secondmove!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings)
end

function apply_change_of_markings_to_lamination!(move::HalfTwist, pl::PantsLamination)
    for i in 1:abs(move.power)
        peel_fold_halftwist!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings, move.power > 0 ? RIGHT : LEFT)
    end
end 

function apply_change_of_markings_to_lamination!(move::Twist, pl::PantsLamination)
    for i in 1:abs(move.power)
        peel_fold_dehntwist!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings, move.power > 0 ? RIGHT : LEFT)
    end
end

function apply_mappingclass_to_lamination!(pmc::PantsMappingClass, pl::PantsLamination)
    # println(pmc.change_of_markings)
    for cm in reverse(pmc.change_of_markings)
        # println("----------------------------------------------------")
        # println(cm)
        # println("Lamination before move:", pl)
        apply_change_of_markings_to_lamination!(cm, pl)
        # println("Lamination after move:", pl)
        # println("----------------------------------------------------")
    end
end

function *(pmc::PantsMappingClass, pl::PantsLamination)
    pl_copy = Donut.Laminations.copy(pl)
    apply_mappingclass_to_lamination!(pmc, pl_copy)
    pl_copy
end


function inv(pmc::PantsMappingClass)
    PantsMappingClass(pmc.pd, [inverse(move) for move in reverse(pmc.change_of_markings)])
end

function isidentity_upto_homology(pmc::PantsMappingClass)
    pd = pmc.pd
    # println(pmc)
    for curveindex in innercurveindices(pd)
        lam = lamination_from_pantscurve(pd, curveindex, BigInt(0))
        # println("Applying mapping class to pantscurve $(curveindex)")
        # println("Original curve: ", lam)
        # println("Image curve: ", pmc * lam)
        # println()
        if lam != pmc * lam
            return false
        end
        lam = lamination_from_transversal(pd, curveindex, BigInt(0))
        # println("Applying mapping class to transversal $(curveindex)")
        # println("Original curve: ", lam)
        # println("Image curve: ", pmc * lam)
        # println()
        if lam != pmc * lam
            return false
        end
    end
    return true
end

function ==(pmc1::PantsMappingClass, pmc2::PantsMappingClass)
    isidentity_upto_homology(pmc1*inv(pmc2))
end

function Base.show(io::IO, pmc::PantsMappingClass)
    println(io, pmc.pd)
    println(io, "Change of markings: ")
    for cm in pmc.change_of_markings
        println(io, cm)
    end
end


function marked_surface(pmc::PantsMappingClass)
    return pmc.pd
end

function example_curve(pmc::PantsMappingClass)
    return lamination_from_pantscurve(pmc.pd, 1, BigInt(0))
end


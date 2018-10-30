


export pantstwist, transversaltwist, PantsMappingClass

using Donut.Pants: ChangeOfPantsMarking, PantsDecomposition, FirstMove, SecondMove, Twist, HalfTwist, pant_nextto_pantscurve
using Donut.Laminations: PantsLamination
import Base.*, Base.==, Base.^
import Donut.Pants.inverse
using Donut.Constants: LEFT, RIGHT

abstract type MappingClass end

struct PantsMappingClass <: MappingClass
    # pd::PantsDecomposition
    change_of_markings::Vector{ChangeOfPantsMarking}  # applied from right to left
end

function copy(pmc::PantsMappingClass)
    PantsMappingClass(Base.copy(pmc.change_of_markings))
end

function identity_mapping_class()
    PantsMappingClass(ChangeOfPantsMarking[])
end

function pantstwist(curveindex::Int, power::Int=1)
    PantsMappingClass([Twist(curveindex, -power)])
end

function halftwist(curveindex::Int, power::Int=1)
    # TODO: we should check that the curve is around two boundaries. Input the pd.
    PantsMappingClass([HalfTwist(curveindex, -power)])
end

function transversaltwist(pd::PantsDecomposition, curveindex::Int, twistdirection::Int=RIGHT)
    # TODO: these first vs second move details shouldn't be here
    leftpant = pant_nextto_pantscurve(pd, curveindex, LEFT)
    rightpant = pant_nextto_pantscurve(pd, curveindex, RIGHT)
    move = leftpant == rightpant ? FirstMove(curveindex) : SecondMove(curveindex)
    PantsMappingClass([move, Twist(curveindex), inverse(move)])
end

function precompose!(pmc::PantsMappingClass, compose_by::PantsMappingClass)
    append!(pmc.change_of_markings, compose_by.change_of_markings)
end

function postcompose!(pmc::PantsMappingClass, compose_by::PantsMappingClass)
    splice!(pmc.change_of_markings, 1:0, compose_by.change_of_markings)
end

function *(pmc1::PantsMappingClass, pmc2::PantsMappingClass)
    pmc = copy(pmc1)
    precompose!(pmc, pmc2)
    pmc
end

function ^(pmc::PantsMappingClass, exp::Int)
    if exp == 0
        return identity_mapping_class()
    end
    new_arr = Iterators.flatten([pmc.change_of_markings for i in 1:abs(exp)])
    new_pmc = PantsMappingClass(collect(new_arr))

    if exp > 0
        return new_pmc
    else
        return inverse(new_pmc)
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
        peel_fold_halftwist!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings, move.power > 1 ? RIGHT : LEFT)
    end
end 

function apply_change_of_markings_to_lamination!(move::Twist, pl::PantsLamination)
    for i in 1:abs(move.power)
        peel_fold_dehntwist!(pl.tt, pl.measure, pl.pd, move.curveindex, pl.encodings, move.power > 1 ? RIGHT : LEFT)
    end
end

function apply_mappingclass_to_lamination!(pmc::PantsMappingClass, pl::PantsLamination)
    for cm in reverse(pmc.change_of_markings)
        apply_change_of_markings_to_lamination!(cm, pl)
    end
end

function *(pmc::PantsMappingClass, pl::PantsLamination)
    pl_copy = deepcopy(pl)
    apply_mappingclass_to_lamination!(pmc, pl_copy)
    pl_copy
end


function inverse(pmc::PantsMappingClass)
    PantsMappingClass(reverse(inverse(move) for move in pmc.change_of_markings))
end

function isidentity_upto_homology(pmc::PantsMappingClass)
    pd = pml.pd
    for curveindex in innerindices(pd)
        lam = lamination_from_pantscurve(pd, curveindex)
        if lam != pmc * lam
            return false
        end
        lam = lamination_from_transversal(pd, curveindex)
        if lam != pmc * lam
            return false
        end
    end
    return true
end

function ==(pmc1::PantsMappingClass, pmc2::PantsMappingClass)
    isidentity_upto_homology(pmc1*pmc2^(-1))
end

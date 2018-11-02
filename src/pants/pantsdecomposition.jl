
export PantsDecomposition, pants, numpants, numpunctures, numboundarycurves, eulerchar, boundarycurveindices, innercurveindices, curveindices,isboundary_pantscurve, isinner_pantscurve, pant_nextto_pantscurve, bdyindex_nextto_pantscurve, pantscurve_nextto_pant, pantboundaries, gluinglist, isfirstmove_curve, issecondmove_curve


using Donut: AbstractSurface
using Donut.Constants: LEFT, RIGHT
using Donut.Utils: otherside
import Base.copy


PANTINDEX = 1
BDYINDEX = 2


"""A pants decomposition of a surface.

It is specified by a gluing list, a list of lists. The list at position i correspond to the i'th pair of pants. Each list contains 3 nonzero integers that encode the three boundary curves. A boundary curve with a positive/negative number is oriented in such a way that the pair of pants is on the left/right of it. (Left and right is defined based on the orientation of the pair of pants.)

The pairs of pants are glued together according to the numbering of the bounding curves. For example, a boundary curve with number +3 and a boundary curve with number -3 result in an orientation-preserving gluing, since one pair of pants will be on the left and the other on the right side of curve 3. If two boundary curves both have number 3, then an orientation of the annulus neighborhood of the curve 3 is chosen, whose orientation agrees with the orientation of the pair of pants `P^+` on one side, but disagrees with the orientation of the pair of pants `P^-` on the other side. So from the perspective of the curve 3, there is a pair of pants on the left and there is one on the right.

If a boundary curve number does not have a pair, it is becomes a boundary component of the surface. Except when it appears in the `onesided_curves` array, in which case its opposite points are glued together, resulting in a one-sided curve in the surface.

The pairs of pants are implicitly `marked` by a triangle whose vertices are in different boundary components. So `[1, 2, 3]` is a different marking of the same pair of pants as `[1, 3, 2]`. However, `[2, 3, 1]` is the same marking as `[1, 2, 3]`. The marking `[1, 2, 3]` means that as the triangle is traversed in the counterclockwise order, we see the curves 1, 2, 3 in order.
"""
struct PantsDecomposition <: AbstractSurface
    pantboundaries::Vector{Tuple{Int, Int, Int}}
    pantscurves::Array{Int, 3}
    numinnerpantscurves::Int

    function PantsDecomposition(pantboundaries::Vector{Tuple{Int, Int, Int}},
        pantscurves::Array{Int, 3}, numinnerpantscurves::Int)
        new(pantboundaries, pantscurves, numinnerpantscurves)
    end

    # gluinglist will not be copied, it is owned by the object
    function PantsDecomposition(gluinglist::Vector{Tuple{Int, Int, Int}})
        curvenumbers = sort(map(abs,Iterators.flatten(gluinglist)))
        maxcurvenumber = curvenumbers[end]
        if Set(curvenumbers) != Set(1:maxcurvenumber)
            error("The pants curves should be numbered from 1 to N where N is the number of pants curves.")
        end
        i = 1
        while i < length(curvenumbers) && curvenumbers[i] == curvenumbers[i+1]
            i += 2
        end
        numinnerpantscurves = div(i, 2)
        if length(curvenumbers) - maxcurvenumber != numinnerpantscurves
            error("The inner pants curves should be numbered from 1 to K and the boundary pants curves from K+1 to N.")
        end
        if length(Set(Iterators.flatten(gluinglist))) != length(Iterators.flatten(gluinglist))
            error("Every number should appear in the gluing list at most once.")
        end

        pantscurves = fill(0, 2, 2, maxcurvenumber)

        for pantindex in eachindex(gluinglist)
            boundaries = gluinglist[pantindex]
            for bdyindex in 1:3
                bdycurve = boundaries[bdyindex]
                abscurve = abs(bdycurve)
                side = bdycurve > 0 ? LEFT : RIGHT
                pantscurves[PANTINDEX, side, abscurve] = pantindex
                pantscurves[BDYINDEX, side, abscurve] = bdyindex
            end
        end

        new(gluinglist, pantscurves, numinnerpantscurves)
    end
end

function isequal_strong(pd1::PantsDecomposition, pd2::PantsDecomposition)
    pd1.pantboundaries == pd2.pantboundaries && pd1.pantscurves == pd2.pantscurves
end


copy(pd::PantsDecomposition) = PantsDecomposition(copy(pd.pantboundaries), copy(pd.pantscurves), pd.numinnerpantscurves)

gluinglist(pd::PantsDecomposition) = pd.pantboundaries

function pantboundaries(pd::PantsDecomposition, pantindex::Int)
    pd.pantboundaries[pantindex]
end

curveindices(pd::PantsDecomposition) = 1:size(pd.pantscurves)[3]
pants(pd::PantsDecomposition) = 1:length(pd.pantboundaries)
numpants(pd::PantsDecomposition) = length(pd.pantboundaries)
eulerchar(pd::PantsDecomposition) = -1*numpants(pd)



function _setpantscurveside(pd::PantsDecomposition, curveindex::Int,
    side::Int, pantindex::Int, bdyindex::Int)
    if curveindex < 0
        side = otherside(side)
    end
    pd.pantscurves[PANTINDEX, side, abs(curveindex)] = pantindex
    pd.pantscurves[BDYINDEX, side, abs(curveindex)] = bdyindex
end

function _setboundarycurves(pd::PantsDecomposition, pantindex::Int, bdy1::Int, bdy2::Int, bdy3::Int)
    pd.pantboundaries[pantindex] = (bdy1, bdy2, bdy3)
end


pant_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = pd.pantscurves[PANTINDEX, curveindex > 0 ? side : otherside(side), abs(curveindex)]

bdyindex_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = pd.pantscurves[BDYINDEX, curveindex > 0 ? side : otherside(side), abs(curveindex)]

pantscurve_nextto_pant(pd::PantsDecomposition, pantindex::Int, bdyindex::Int) = pantboundaries(pd, pantindex)[bdyindex]



const BDYCURVE = 1
const TORUS_NBHOOD = 2
const PUNCTURED_SPHERE_NBHOOD = 3

function pantscurve_type(pd::PantsDecomposition, curveindex::Int)
    leftpant = pant_nextto_pantscurve(pd, curveindex, LEFT)
    rightpant = pant_nextto_pantscurve(pd, curveindex, RIGHT)
    if leftpant == 0 || rightpant == 0 
        return BDYCURVE
    end
    if leftpant != rightpant
        return PUNCTURED_SPHERE_NBHOOD
    else
        return TORUS_NBHOOD
    end
end

isinner_pantscurve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) != BDYCURVE
isboundary_pantscurve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == BDYCURVE

isfirstmove_curve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == TORUS_NBHOOD
issecondmove_curve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == PUNCTURED_SPHERE_NBHOOD

innercurveindices(pd::PantsDecomposition) = 1:pd.numinnerpantscurves
# filter(x -> isinner_pantscurve(pd, x), curveindices(pd))
boundarycurveindices(pd::PantsDecomposition) = pd.numinnerpantscurves+1:size(pd.pantscurves)[3]
numboundarycurves(pd::PantsDecomposition) = length(boundarycurveindices(pd))
numpunctures(pd::PantsDecomposition) = numboundarycurves(pd)




function Base.show(io::IO, pd::PantsDecomposition)
    print(io, "PantsDecomposition with gluing list [")
    for ls in gluinglist(pd)
        print(io, "[$(ls[1]), $(ls[2]), $(ls[3])]")
    end
    print(io, "]")
end


function pantsdecomposition_humphries(genus::Int)
    a = [(1, 2, -1)]
    for i in 1:genus-2
        push!(a, (3*i+1, 3*i, 1-3*i))
        push!(a, (-3*i, -1-3*i, 2+3*i))
    end
    push!(a, (-3*genus+3, -3*genus+4, 3*genus-3))
    PantsDecomposition(a)
end

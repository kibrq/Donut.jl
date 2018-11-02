
export PantsDecomposition, pants, numpants, numpunctures, numboundarycurves, eulerchar, boundarycurveindices, innercurveindices, curveindices,isboundary_pantscurve, isinner_pantscurve, pant_nextto_pantscurve, bdyindex_nextto_pantscurve, istwosided_pantscurve, isonesided_pantscurve, ispantscurveside_orientationpreserving, pantscurve_nextto_pant, ispantend_orientationpreserving, pantend_to_pantscurveside, pantboundaries, gluinglist, isfirstmove_curve, issecondmove_curve


using Donut: AbstractSurface
using Donut.Constants: LEFT, RIGHT
using Donut.Utils: otherside
import Base.copy

PANTSCURVE_GLUED_TO_SELF = -1
# NOPANT_THISSIDE = 0


PANTINDEX = 1
BDYINDEX = 2

# mutable struct PantEnd
#     pantindex::Int
#     bdyindex::Int   # 1, 2 or 3
# end
# PantEnd() = PantEnd(NOPANT_THISSIDE, 0)
# exists(pantend::PantEnd) = pantend.pantindex != NOPANT_THISSIDE
# isequal(x1::PantEnd, x2::PantEnd) = x1.pantindex == x2.pantindex && x1.bdyindex == x2.bdyindex

# struct PantsCurve
#     neighboring_pantends::Vector{PantEnd}  # length 2
# end
# isequal_strong(pc1::PantsCurve, pc2::PantsCurve) = isequal(pc1.neighboring_pantends[1], pc2.neighboring_pantends[1]) && isequal(pc1.neighboring_pantends[2], pc2.neighboring_pantends[2])


# PantsCurve() = PantsCurve([PantEnd(), PantEnd()])

# occupiedsides(pantscurve::PantsCurve) = [side for side in (LEFT, RIGHT)
#     if exists(pantscurve.neighboring_pantends[side])]

# exists(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) != 0
# isboundary(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 1
# isinner(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 2

# isside_occupied(sidedata::AbstractArray{Int,1}) = sidedata[PANTINDEX] != 0
# occupiedsides(curvedata::AbstractArray{Int,2}) = Tuple(side for side in (LEFT, RIGHT) if isside_occupied(view(curvedata, :, side)))
# exists(curvedata::AbstractArray{Int,2}) = curvedata[PANTINDEX, LEFT] != 0 || curvedata[PANTINDEX, RIGHT]

"""A pants decomposition of a surface.

It is specified by a gluing list, a list of lists. The list at position i correspond to the i'th pair of pants. Each list contains 3 nonzero integers that encode the three boundary curves. A boundary curve with a positive/negative number is oriented in such a way that the pair of pants is on the left/right of it. (Left and right is defined based on the orientation of the pair of pants.)

The pairs of pants are glued together according to the numbering of the bounding curves. For example, a boundary curve with number +3 and a boundary curve with number -3 result in an orientation-preserving gluing, since one pair of pants will be on the left and the other on the right side of curve 3. If two boundary curves both have number 3, then an orientation of the annulus neighborhood of the curve 3 is chosen, whose orientation agrees with the orientation of the pair of pants `P^+` on one side, but disagrees with the orientation of the pair of pants `P^-` on the other side. So from the perspective of the curve 3, there is a pair of pants on the left and there is one on the right.

If a boundary curve number does not have a pair, it is becomes a boundary component of the surface. Except when it appears in the `onesided_curves` array, in which case its opposite points are glued together, resulting in a one-sided curve in the surface.

The pairs of pants are implicitly `marked` by a triangle whose vertices are in different boundary components. So `[1, 2, 3]` is a different marking of the same pair of pants as `[1, 3, 2]`. However, `[2, 3, 1]` is the same marking as `[1, 2, 3]`. The marking `[1, 2, 3]` means that as the triangle is traversed in the counterclockwise order, we see the curves 1, 2, 3 in order.
"""
struct PantsDecomposition <: AbstractSurface
    pantboundaries::Vector{Tuple{Int, Int, Int}}
    pantscurves::Array{Int, 3}

    function PantsDecomposition(pantboundaries::Vector{Tuple{Int, Int, Int}},
        pantscurves::Array{Int, 3})
        new(pantboundaries, pantscurves)
    end

    # gluinglist will not be copied, it is owned by the object
    function PantsDecomposition(gluinglist::Vector{Tuple{Int, Int, Int}},
                onesided_curves::Vector{Int}=Int[])

        allcurves = sort(map(abs,Iterators.flatten(gluinglist)))
        maxcurvenumber = allcurves[end]

        if allcurves[1] == 0
            error("Pants curves cannot be numbered by 0")
        end

        pantscurves = fill(0, 2, 2, maxcurvenumber)
        # pantscurves = [PantsCurve() for i in 1:maxcurvenumber]

        for pantindex in eachindex(gluinglist)
            boundaries = gluinglist[pantindex]
            for bdyindex in 1:3
                bdycurve = boundaries[bdyindex]
                abscurve = abs(bdycurve)
                newside = bdycurve > 0 ? LEFT : RIGHT
                leftpant = pantscurves[PANTINDEX, LEFT, abscurve]
                rightpant = pantscurves[PANTINDEX, RIGHT, abscurve]

                if leftpant != 0 && rightpant != 0
                    error("Each curve can appear in the gluing list at most twice")
                elseif leftpant != 0
                    newside = RIGHT
                elseif rightpant != 0 
                    newside = LEFT
                end
                pantscurves[PANTINDEX, newside, abscurve] = pantindex
                pantscurves[BDYINDEX, newside, abscurve] = bdyindex
            end
        end

        for i in onesided_curves
            leftpant = pantscurves[PANTINDEX, LEFT, i]
            rightpant = pantscurves[PANTINDEX, RIGHT, i]
            if leftpant != 0 && rightpant != 0 || leftpant == 0 && rightpant == 0
                error("Curve $(i) is not a boundary curve, so it cannot be glued to itself to obtain one-sided curve.")
            end
            emptyside = leftpant != 0 ? RIGHT : LEFT 
            pantscurves[PANTINDEX, emptyside, i] = PANTSCURVE_GLUED_TO_SELF
        end
        new(gluinglist, pantscurves)
    end
end

function isequal_strong(pd1::PantsDecomposition, pd2::PantsDecomposition)
    pd1.pantboundaries == pd2.pantboundaries && pd1.pantscurves == pd2.pantscurves
end


copy(pd::PantsDecomposition) = PantsDecomposition(copy(pd.pantboundaries), copy(pd.pantscurves))

gluinglist(pd::PantsDecomposition) = pd.pantboundaries

function check_pantindex_validity(pd::PantsDecomposition, pantindex::Int)
    if !(1 <= pantindex <= length(pd.pantboundaries))
        error("There is no pant with index $(pantindex).")
    end
end

function pantboundaries(pd::PantsDecomposition, pantindex::Int)
    check_pantindex_validity(pd, pantindex)
    pd.pantboundaries[pantindex]
end

curveindices(pd::PantsDecomposition) = (i for i in 1:size(pd.pantscurves)[3] if pd.pantscurves[PANTINDEX, LEFT, i] != 0 || pd.pantscurves[PANTINDEX, RIGHT, i] != 0)
pants(pd::PantsDecomposition) = collect(1:length(pd.pantboundaries))
numpants(pd::PantsDecomposition) = length(pd.pantboundaries)
eulerchar(pd::PantsDecomposition) = -1*numpants(pd)

function check_pantcurve_validity(pd::PantsDecomposition, curveindex::Int)
    absindex = abs(curveindex)
    if !(1 <= absindex <= size(pd.pantscurves)[3]) || (pd.pantscurves[PANTINDEX, LEFT, absindex] == 0 && pd.pantscurves[PANTINDEX, RIGHT, absindex] == 0)
        error("There is no pants curve with index $(curveindex).")
    end
end

function _getcurvedata(pd::PantsDecomposition, curveindex::Int)
    check_pantcurve_validity(pd, curveindex)
    view(pd.pantscurves, :, :, abs(curveindex))
end



function _setpantscurveside(pd::PantsDecomposition, curveindex::Int,
    side::Int, pantindex::Int, bdyindex::Int)
    curvedata = _getcurvedata(pd, curveindex)
    if curveindex < 0
        side = otherside(side)
    end
    curvedata[PANTINDEX, side] = pantindex
    curvedata[BDYINDEX, side] = bdyindex
end

function _setboundarycurves(pd::PantsDecomposition, pantindex::Int, bdy1::Int, bdy2::Int, bdy3::Int)
    check_pantindex_validity(pd, pantindex)
    pd.pantboundaries[pantindex] = (bdy1, bdy2, bdy3)
end


# function pantscurveside_to_pantend(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT)
#     _getpantscurve(pd, curveindex).neighboring_pantends[curveindex > 0 ? side : otherside(side)]
# end


pant_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = _getcurvedata(pd, curveindex)[PANTINDEX, curveindex > 0 ? side : otherside(side)]

bdyindex_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = _getcurvedata(pd, curveindex)[BDYINDEX, curveindex > 0 ? side : otherside(side)]

pantscurve_nextto_pant(pd::PantsDecomposition, pantindex::Int, bdyindex::Int) = pantboundaries(pd, pantindex)[bdyindex]

function pantend_to_pantscurveside(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)
    boundaries = pantboundaries(pd, pantindex)
    curveindex = boundaries[bdyindex]

    for side in (LEFT, RIGHT)
        pant = pant_nextto_pantscurve(pd, curveindex, side)
        bdy = bdyindex_nextto_pantscurve(pd, curveindex, side)
        if pant == pantindex && bdy == bdyindex
            return (curveindex, side)
        end
    end
    @assert false
end





const BDYCURVE = 1
const TORUS_NBHOOD = 2
const PUNCTURED_SPHERE_NBHOOD = 3
const KLEIN_BOTTLE_NBHOOD = 4
const ONESIDED_CURVE = 5

function pantscurve_type(pd::PantsDecomposition, curveindex::Int)
    curvedata = _getcurvedata(pd, curveindex)  # raises error if invalid curveindex
    if curvedata[PANTINDEX, LEFT] == 0 || curvedata[PANTINDEX, RIGHT] == 0 
        return BDYCURVE
    end
    if curvedata[PANTINDEX, LEFT] == PANTSCURVE_GLUED_TO_SELF || curvedata[PANTINDEX, RIGHT] == PANTSCURVE_GLUED_TO_SELF
        return ONESIDED_CURVE
    end
    if curvedata[PANTINDEX, LEFT] != curvedata[PANTINDEX, RIGHT]
        return PUNCTURED_SPHERE_NBHOOD
    end
    leftnum = pd.pantboundaries[curvedata[PANTINDEX, LEFT]][curvedata[BDYINDEX, LEFT]]
    rightnum = pd.pantboundaries[curvedata[PANTINDEX, RIGHT]][curvedata[BDYINDEX, RIGHT]]
    if leftnum == rightnum
        return KLEIN_BOTTLE_NBHOOD
    elseif leftnum == -rightnum
        return TORUS_NBHOOD
    else
        @assert false
    end
end

isinner_pantscurve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) != BDYCURVE
isboundary_pantscurve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == BDYCURVE
istwosided_pantscurve(pd::PantsDecomposition, curveindex::Int) = !(pantscurve_type(pd, curveindex) in (BDYCURVE, ONESIDED_CURVE))
isonesided_pantscurve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == ONESIDED_CURVE

isfirstmove_curve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == TORUS_NBHOOD
issecondmove_curve(pd::PantsDecomposition, curveindex::Int) = pantscurve_type(pd, curveindex) == PUNCTURED_SPHERE_NBHOOD

innercurveindices(pd::PantsDecomposition) = (c for c in curveindices(pd) if isinner_pantscurve(pd, c))
# filter(x -> isinner_pantscurve(pd, x), curveindices(pd))
boundarycurveindices(pd::PantsDecomposition) = (c for c in curveindices(pd) if isboundary_pantscurve(pd, c))
numboundarycurves(pd::PantsDecomposition) = length(Tuple(boundarycurveindices(pd)))
numpunctures(pd::PantsDecomposition) = numboundarycurves(pd)






function ispantscurveside_orientationpreserving(pd::PantsDecomposition, curveindex::Int, side::Int)
    curveindex2 = pantscurve_nextto_pant(pd, pant_nextto_pantscurve(pd, curveindex, side), bdyindex_nextto_pantscurve(pd, curveindex, side))
    if side == LEFT
        return curveindex == curveindex2
    elseif side == RIGHT
        return curveindex != curveindex2
    end
end

function ispantend_orientationpreserving(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)
    curveindex, side = pantend_to_pantscurveside(pd, pantindex, bdyindex)
    ispantscurveside_orientationpreserving(pd, curveindex, side)
end

function Base.show(io::IO, pd::PantsDecomposition)
    print(io, "PantsDecomposition with gluing list [")
    for ls in gluinglist(pd)
        print(io, "[$(ls[1]), $(ls[2]), $(ls[3])]")
    end
    print(io, "]")
    onesided_curves = [c for c in curveindices(pd) if isonesided_pantscurve(pd, c)]
    if length(onesided_curves) > 0
        print(io, " and one-sided curves ")
        print(io, onesided_curves)
    end
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

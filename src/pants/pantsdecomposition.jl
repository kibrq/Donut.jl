
export PantsDecomposition, pants, numpants, numpunctures, numboundarycurves, eulerchar, boundarycurveindices, innercurveindices, curveindices,isboundary_pantscurve, isinner_pantscurve, pant_nextto_pantscurve, bdyindex_nextto_pantscurve, istwosided_pantscurve, isonesided_pantscurve, ispantscurveside_orientationpreserving, pantscurve_nextto_pant, ispantend_orientationpreserving, pantend_to_pantscurveside, pantscurveside_to_pantend, pantboundaries, gluinglist, isfirstmove_curve, issecondmove_curve


using Donut: AbstractSurface
using Donut.Constants: LEFT, RIGHT
using Donut.Utils: otherside

PANTSCURVE_GLUED_TO_SELF = -1
NOPANT_THISSIDE = 0



mutable struct PantEnd
    pantindex::Int
    bdyindex::Int   # 1, 2 or 3
end
PantEnd() = PantEnd(NOPANT_THISSIDE, 0)
exists(pantend::PantEnd) = pantend.pantindex != NOPANT_THISSIDE
isequal(x1::PantEnd, x2::PantEnd) = x1.pantindex == x2.pantindex && x1.bdyindex == x2.bdyindex

struct PantsCurve
    neighboring_pantends::Vector{PantEnd}  # length 2
end
isequal_strong(pc1::PantsCurve, pc2::PantsCurve) = isequal(pc1.neighboring_pantends[1], pc2.neighboring_pantends[1]) && isequal(pc1.neighboring_pantends[2], pc2.neighboring_pantends[2])


PantsCurve() = PantsCurve([PantEnd(), PantEnd()])

occupiedsides(pantscurve::PantsCurve) = [side for side in (LEFT, RIGHT)
    if exists(pantscurve.neighboring_pantends[side])]

# exists(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) != 0
isboundary(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 1
isinner(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 2


"""A pants decomposition of a surface.

It is specified by a gluing list, a list of lists. The list at position i correspond to the i'th pair of pants. Each list contains 3 nonzero integers that encode the three boundary curves. A boundary curve with a positive/negative number is oriented in such a way that the pair of pants is on the left/right of it. (Left and right is defined based on the orientation of the pair of pants.)

The pairs of pants are glued together according to the numbering of the bounding curves. For example, a boundary curve with number +3 and a boundary curve with number -3 result in an orientation-preserving gluing, since one pair of pants will be on the left and the other on the right side of curve 3. If two boundary curves both have number 3, then an orientation of the annulus neighborhood of the curve 3 is chosen, whose orientation agrees with the orientation of the pair of pants `P^+` on one side, but disagrees with the orientation of the pair of pants `P^-` on the other side. So from the perspective of the curve 3, there is a pair of pants on the left and there is one on the right.

If a boundary curve number does not have a pair, it is becomes a boundary component of the surface. Except when it appears in the `onesided_curves` array, in which case its opposite points are glued together, resulting in a one-sided curve in the surface.

The pairs of pants are implicitly `marked` by a triangle whose vertices are in different boundary components. So `[1, 2, 3]` is a different marking of the same pair of pants as `[1, 3, 2]`. However, `[2, 3, 1]` is the same marking as `[1, 2, 3]`. The marking `[1, 2, 3]` means that as the triangle is traversed in the counterclockwise order, we see the curves 1, 2, 3 in order.
"""
struct PantsDecomposition <: AbstractSurface
    pantboundaries::Vector{Tuple{Int, Int, Int}}
    pantscurves::Vector{PantsCurve}

    # gluinglist will not be copied, it is owned by the object
    function PantsDecomposition(gluinglist::Vector{Tuple{Int, Int, Int}},
                onesided_curves::Array{Int, 1}=Int[])

        curvenumbers = sort(map(abs,Iterators.flatten(gluinglist)))
        maxcurvenumber = curvenumbers[end]
        if Set(curvenumbers) != Set(1:maxcurvenumber)
            error("The pants curves should be numbered from 1 to N where N is the number of pants curves.")
        end

        pantscurves = [PantsCurve() for i in 1:maxcurvenumber]

        for pantindex in eachindex(gluinglist)
            boundaries = gluinglist[pantindex]
            for bdyindex in 1:3
                bdycurve = boundaries[bdyindex]
                pantscurve = pantscurves[abs(bdycurve)]
                occsides = occupiedsides(pantscurve)
                newside = bdycurve > 0 ? LEFT : RIGHT

                if length(occsides) == 2
                    error("Each curve can appear in the gluing list at most twice")
                elseif length(occsides) == 1 && newside == occsides[1]
                    # pant.isorientation_reversing[bdyindex] = true
                    newside = otherside(newside)
                end
                pantscurve.neighboring_pantends[newside] =
                        PantEnd(pantindex, bdyindex)
            end
        end

        for i in onesided_curves
            pantscurve = pantscurves[abs(i)]
            if !isboundary(pantscurve)
                error("Curve $(i) is not a boundary curve, so it cannot be glued to itself to obtain one-sided curve.")
            end
            @assert length(occupiedsides(pantscurve)) == 1
            occupiedside = occupiedsides(pantscurve)[1]
            emptyside = otherside(occupiedside)
            pantend = pantscurve.neighboring_pantends[emptyside]
            pantend.pantindex = PANTSCURVE_GLUED_TO_SELF
        end
        new(gluinglist, pantscurves)
    end
end

function isequal_strong(pd1::PantsDecomposition, pd2::PantsDecomposition)
    pd1.pantboundaries == pd2.pantboundaries && length(pd1.pantscurves) == length(pd2.pantscurves) && all(isequal_strong(pd1.pantscurves[i], pd2.pantscurves[i]) for i in eachindex(pd1.pantscurves))
end


copy(pd::PantsDecomposition) = deepcopy(pd)

gluinglist(pd::PantsDecomposition) = pd.pantboundaries

function check_pantindex_validity(pd::PantsDecomposition, pantindex::Int)
    if !(1 <= pantindex <= length(pd.pantboundaries) && pd.pantboundaries[pantindex][1] != 0)
        error("There is no pant with index $(pantindex).")
    end
end

function pantboundaries(pd::PantsDecomposition, pantindex::Int)
    check_pantindex_validity(pd, pantindex)
    pd.pantboundaries[pantindex]
end
# this could return an iterator
curveindices(pd::PantsDecomposition) = 1:length(pd.pantscurves)
pants(pd::PantsDecomposition) = collect(1:length(pd.pantboundaries))
numpants(pd::PantsDecomposition) = length(pd.pantboundaries)
eulerchar(pd::PantsDecomposition) = -1*numpants(pd)

function check_pantcurve_validity(pd::PantsDecomposition, curveindex::Int)
    if !(1 <= abs(curveindex) <= length(pd.pantscurves))
        error("There is no pants curve with index $(curveindex).")
    end
end

function _getpantscurve(pd::PantsDecomposition, curveindex::Int)
    check_pantcurve_validity(pd, curveindex)
    pd.pantscurves[abs(curveindex)]
end



function _setpantscurveside_to_pantend(pd::PantsDecomposition, curveindex::Int,
    side::Int, pantindex::Int, bdyindex::Int)
    pantscurve = _getpantscurve(pd, curveindex)
    if curveindex < 0
        side = otherside(side)
    end
    pantscurve.neighboring_pantends[side].pantindex = pantindex
    pantscurve.neighboring_pantends[side].bdyindex = bdyindex
end

function _setboundarycurves(pd::PantsDecomposition, pantindex::Int, bdy1::Int, bdy2::Int, bdy3::Int)
    check_pantindex_validity(pd, pantindex)
    pd.pantboundaries[pantindex] = (bdy1, bdy2, bdy3)
end


function pantscurveside_to_pantend(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT)
    _getpantscurve(pd, curveindex).neighboring_pantends[curveindex > 0 ? side : otherside(side)]
end


pant_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = pantscurveside_to_pantend(pd, curveindex, side).pantindex

bdyindex_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = pantscurveside_to_pantend(pd, curveindex, side).bdyindex

pantscurve_nextto_pant(pd::PantsDecomposition, pantindex::Int, bdyindex::Int) = pantboundaries(pd, pantindex)[bdyindex]

function pantend_to_pantscurveside(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)
    boundaries = pantboundaries(pd, pantindex)
    curveindex = boundaries[bdyindex]

    for side in (LEFT, RIGHT)
        pantend = pantscurveside_to_pantend(pd, curveindex, side)
        if pantend.pantindex == pantindex && pantend.bdyindex == bdyindex
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
    pantscurve = _getpantscurve(pd, curveindex)  # raises error if invalid curveindex
    if isboundary(pantscurve)
        return BDYCURVE
    end
    pantends = pantscurve.neighboring_pantends
    left_pantend = pantends[LEFT]
    right_pantend = pantends[RIGHT]
    if left_pantend.pantindex == PANTSCURVE_GLUED_TO_SELF || right_pantend.pantindex == PANTSCURVE_GLUED_TO_SELF
        return ONESIDED_CURVE
    end
    if left_pantend.pantindex != right_pantend.pantindex
        return PUNCTURED_SPHERE_NBHOOD
    end
    leftnum = pd.pantboundaries[left_pantend.pantindex][left_pantend.bdyindex]
    rightnum = pd.pantboundaries[right_pantend.pantindex][right_pantend.bdyindex] 
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

innercurveindices(pd::PantsDecomposition) = filter(x -> isinner_pantscurve(pd, x), curveindices(pd))
boundarycurveindices(pd::PantsDecomposition) = filter(x -> isboundary_pantscurve(pd, x), curveindices(pd))
numboundarycurves(pd::PantsDecomposition) = length(boundarycurveindices(pd))
numpunctures(pd::PantsDecomposition) = numboundarycurves(pd)






function ispantscurveside_orientationpreserving(pd::PantsDecomposition, curveindex::Int, side::Int)
    pantend = pantscurveside_to_pantend(pd, curveindex, side)
    curveindex2 = pantscurve_nextto_pant(pd, pantend.pantindex, pantend.bdyindex)
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
    onesided_curves = filter(x -> isonesided_pantscurve(pd, x), curveindices(pd))
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

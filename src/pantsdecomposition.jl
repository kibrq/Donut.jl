export PantsDecomposition, pants, numpants, numpunctures, numboundarycurves, eulerchar, boundarycurveindices, innercurveindices, curveindices, ispantscurve, isboundary_pantscurve, isinner_pantscurve, pant_nextto_pantscurve, istwosided_pantscurve, isonesided_pantscurve


struct Pant
    boundaries::Array{Int, 1}  # length 3
    isorientation_reversing::Array{Bool, 1}  # length 3
end


mutable struct PantEnd
    pantnumber::Int
    bdyindex::Int   # 1, 2 or 3
end
PantEnd() = PantEnd(NOPANT_THISSIDE, 0)
exists(pantend::PantEnd) = pantend.pantnumber != NOPANT_THISSIDE



struct PantsCurve
    neighboring_pantsends::Array{PantEnd, 1}  # length 2
end



PantsCurve() = PantsCurve([PantEnd(), PantEnd()])

occupiedsides(pantscurve::PantsCurve) = [side for side in (LEFT, RIGHT) 
    if exists(pantscurve.neighboring_pantsends[side])]

exists(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) != 0
isboundary(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 1
isinner(pantscurve::PantsCurve) = length(occupiedsides(pantscurve)) == 2


"""A pants decomposition of a surface.

It is specified by a gluing list, a list of lists. The list at position i correspond to the i'th pair of pants. Each list contains 3 nonzero integers that encode the three boundary curves. A boundary curve with a positive/negative number is oriented in such a way that the pair of pants is on the left/right of it. (Left and right is defined based on the orientation of the pair of pants.)

The pairs of pants are glued together according to the numbering of the bounding curves. For example, a boundary curve with number +3 and a boundary curve with number -3 result in an orientation-preserving gluing, since one pair of pants will be on the left and the other on the right side of curve 3. If two boundary curves both have number 3, then an orientation of the annulus neighborhood of the curve 3 is chosen, whose orientation agrees with the orientation of the pair of pants `P^+` on one side, but disagrees with the orientation of the pair of pants `P^-` on the other side. So from the perspective of the curve 3, there is a pair of pants on the left and there is one on the right.

If a boundary curve number does not have a pair, it is becomes a boundary component of the surface. Except when it appears in the `onesided_curves` array, in which case its opposite points are glued together, resulting in a one-sided curve in the surface.

The pairs of pants are implicitly `marked` by a triangle whose vertices are in different boundary components. So `[1, 2, 3]` is a different marking of the same pair of pants as `[1, 3, 2]`. However, `[2, 3, 1]` is the same marking as `[1, 2, 3]`. The marking `[1, 2, 3]` means that as the triangle is traversed in the counterclockwise order, we see the curves 1, 2, 3 in order.
"""
struct PantsDecomposition <: AbstractSurface
    pants::Array{Pant, 1}
    pantscurves::Array{PantsCurve, 1}

    # gluinglist will not be deepcopied, it is owned by the object
    function PantsDecomposition(gluinglist::Array{Array{Int, 1}, 1},
                onesided_curves::Array{Int, 1}=Int[])
        num_pants = length(gluinglist)
        for i in 1:num_pants
            ls = gluinglist[i]
            if length(ls) != 3
                error("All pants should have three boundaries")
            end
        end

        allcurves = sort(map(abs,collect(Iterators.flatten(gluinglist))))
        maxcurvenumber = allcurves[end]
        # for i in 1:length(allcurves)-2
        #     if allcurves[i] == allcurves[i+1] == allcurves[i+2]
        #         error("Each curve can appear in the gluing list at most once")
        #     end
        # end

        if allcurves[1] == 0
            error("Pants curves cannot be numbered by 0")
        end

        pants = [Pant(ls, [false, false, false]) for ls in gluinglist]
        pantscurves = [PantsCurve() for i in 1:maxcurvenumber]

        for pantindex in eachindex(pants)
            pant = pants[pantindex]
            for bdyindex in 1:3
                bdycurve = pant.boundaries[bdyindex]
                pantscurve = pantscurves[abs(bdycurve)]
                occsides = occupiedsides(pantscurve)
                newside = bdycurve > 0 ? LEFT : RIGHT

                if length(occsides) == 2
                    error("Each curve can appear in the gluing list at most twice")
                elseif length(occsides) == 1 && newside == occsides[1]
                    pant.isorientation_reversing[bdyindex] = true
                    newside = otherside(newside)
                end
                pantscurve.neighboring_pantsends[newside] =
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
            pantend = pantscurve.neighboring_pantsends[emptyside]
            pantend.pantnumber = PANTSCURVE_GLUED_TO_SELF
        end
        new(pants, pantscurves)
    end
end


function pantend_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) 
    if curveindex < 0
        side = otherside(side)
    end
    _pantscurve(pd, curveindex).neighboring_pantsends[side]
end

function _pantscurve(pd::PantsDecomposition, curveindex::Int)
    if !ispantscurve(pd, curveindex)
        error("There is no pants curve with index $(curveindex).")
    end
    pd.pantscurves[abs(curveindex)]
end

pant_nextto_pantscurve(pd::PantsDecomposition, curveindex::Int, side::Int=LEFT) = pantend_nextto_pantscurve(pd, curveindex, side).pantnumber

function ispantscurve(pd::PantsDecomposition, curveindex::Int)
    if 1 <= abs(curveindex) <= length(pd.pantscurves)
        pantscurve = pd.pantscurves[abs(curveindex)]
        if exists(pantscurve)
            return true
        end
    end
    false
end

isinner_pantscurve(pd::PantsDecomposition, curveindex::Int) = ispantscurve(pd, curveindex) && isinner(_pantscurve(pd, curveindex))

isboundary_pantscurve(pd::PantsDecomposition, curveindex::Int) = ispantscurve(pd, curveindex) && isboundary(_pantscurve(pd, curveindex))

# this could return an iterator
curveindices(pd::PantsDecomposition) = [i for i in eachindex(pd.pantscurves) if exists(pd.pantscurves[i])]

innercurveindices(pd::PantsDecomposition) = filter(x -> isinner_pantscurve(pd, x), curveindices(pd))

boundarycurveindices(pd::PantsDecomposition) = filter(x -> isboundary_pantscurve(pd, x), 
curveindices(pd))

numboundarycurves(pd::PantsDecomposition) = length(boundarycurveindices(pd))

pants(pd::PantsDecomposition) = collect(1:length(pd.pants))

numpants(pd::PantsDecomposition) = length(pd.pants)

numpunctures(pd::PantsDecomposition) = numboundarycurves(pd)

eulerchar(pd::PantsDecomposition) = -1*numpants(pd)

function isonesided_pantscurve(pd::PantsDecomposition, curveindex::Int)
    if !isinner_pantscurve(pd, curveindex)
        return false
    end
    pantscurve = _pantscurve(pd, curveindex)
    pantsends = pantscurve.neighboring_pantsends
    any(pantsends[side].pantnumber == PANTSCURVE_GLUED_TO_SELF for side in (LEFT, RIGHT))
end 

istwosided_pantscurve(pd::PantsDecomposition, curveindex::Int) = isinner_pantscurve(pd, curveindex) && !isonesided_pantscurve(pd, curveindex)

gluinglist(pd::PantsDecomposition) = [pant.boundaries for pant in pd.pants]


# function _repr(pd::PantsDecomposition)
#     s = "PantsDecomposition with gluing list "
#     s *= "$(gluinglist(pd))"
#     onesided_curves = filter(x -> isonesided_pantscurve(pd, x), pantscurves(pd))
#     if length(onesided_curves) > 0
#         s *= " and one-sided curves $(onesided_curves)"
#     end
#     s
# end

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

function elementarymove_type(pd::PantsDecomposition, curveindex::Int)
    if isboundary_pantscurve(pd, curveindex)
        return 
    end
end

function applymove_type2!(pd::PantsDecomposition, curveindex::Int)
    @assert istwosided_pantscurve(pd, curveindex)
    @assert pant_nextto_pantscurve(pd, curveindex, LEFT) != pant_nextto_pantscurve(pd, curveindex, RIGHT)

end


function applymove_type1!(pd::PantsDecomposition, curveindex::Int)
    @assert istwosided_pantscurve(pd, curveindex)
    @assert pant_nextto_pantscurve(pd, curveindex, LEFT) != pant_nextto_pantscurve(pd, curveindex, RIGHT)

end


function applymove_onesided_to_onesided(pd::PantsDecomposition, curveindex::Int)
    @assert isonesided_pantscurve(pd, curveindex)

end

function applymove_twoonesided_to_twosided(pd::PantsDecomposition, curveindex1::Int, curveindex2::Int)

end

function applymove_twosided_to_twoonesided(pd::PantsDecomposition, curve)

end


function twist_marking!(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)

end


function pantsdecomposition_humphries(genus::Int)
    a = [[1, 2, -1]]
    for i in 1:genus-1
        push!(a, [3*i+1, 3*i, 1-3*i])
        push!(a, [-3*i, -1-3*i, 2+3*i])
    end
    push!(a, [-3*genus+3, -3*genus+4, 3*genus-3])
    a
end

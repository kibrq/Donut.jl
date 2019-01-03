
export PantsDecomposition, regions, numregions, numpunctures, numboundarycurves, eulerchar, 
    boundarycurves, innercurves, separators,isboundary_pantscurve, 
    isinner_pantscurve, separator_to_region, separator_to_bdyindex, 
    region_to_separator, region_to_separators, gluinglist, isfirstmove_curve, 
    issecondmove_curve, nextindex, previndex, BdyIndex


using Donut: AbstractSurface
using Donut.Constants


abstract type MarkedSurface <: AbstractSurface end

@enum BdyIndex::Int8 BDY1=1 BDY2=2 BDY3=3

function nextindex(bdyindex::BdyIndex)
    if bdyindex == BDY1
        return BDY2
    elseif bdyindex == BDY2
        return BDY3
    else
        return BDY1
    end
end

function previndex(bdyindex::BdyIndex)
    if bdyindex == BDY1
        return BDY3
    elseif bdyindex == BDY2
        return BDY1
    else
        return BDY2
    end
end



function check_gluinglist(gluinglist::Vector{<:Tuple{Int, Int, Int}})
    abslabels = sort(map(abs,Iterators.flatten(gluinglist)))
    maxlabel = abslabels[end]
    if Set(abslabels) != Set(1:maxlabel)
        error("The labels should be consecutive from 1 to N.")
    end
    i = 1
    while i < length(abslabels) && abslabels[i] == abslabels[i+1]
        i += 2
    end
    numpaired_labels = div(i, 2)
    if length(abslabels) - maxlabel != numpaired_labels
        error("The paired labels should be from 1 to K and the unpaired labels from K+1 to N.")
    end
    if length(Set(Iterators.flatten(gluinglist))) != length(Iterators.flatten(gluinglist))
        error("Every label should appear in the gluing list at most once.")
    end
    return maxlabel, numpaired_labels
end


function init_separator_arrays!(maxlabel::Integer, gluinglist::Vector{<:Tuple{Int, Int, Int}})
    separator_to_region = zeros(Int16, 2, maxlabel)
    separator_to_bdyindex = fill(BdyIndex(1), 2, maxlabel)

    for region in eachindex(gluinglist)
        boundaries = gluinglist[region]
        for bdyindex in 1:3
            bdy = boundaries[bdyindex]
            absbdy = abs(bdy)
            side = bdy > 0 ? LEFT : RIGHT
            separator_to_region[Int(side), absbdy] = region
            separator_to_bdyindex[Int(side), absbdy] = BdyIndex(bdyindex)
        end
    end    

    return separator_to_region, separator_to_bdyindex
end



struct Triangulation <: MarkedSurface
    region_to_separators::Vector{Tuple{Int16, Int16, Int16}}
    separator_to_region::Array{Int16, 2}
    separator_to_bdyindex::Array{BdyIndex, 2}

    function Triangulation(gluinglist::Vector{<:Tuple{Int, Int, Int}})
        maxedgenumber, numpaired_labels = check_gluinglist(gluinglist)
        if numpaired_labels != maxedgenumber
            error("The negative of every label should also appear in the gluing list.")
        end

        separator_to_region, separator_to_bdyindex = init_separator_arrays!(maxedgenumber, gluinglist)
        new(gluinglist, separator_to_region, separator_to_bdyindex)
    end
end

Base.copy(t::Triangulation) = Triangulation(copy(t.region_to_separators), 
    copy(t.separator_to_region), copy(t.separator_to_bdyindex))



"""A pants decomposition of a surface.

It is specified by a gluing list, a list of lists. The list at position i correspond to the i'th pair of pants. Each list contains 3 nonzero integers that encode the three boundary curves. A boundary curve with a positive/negative number is oriented in such a way that the pair of pants is on the left/right of it. (Left and right is defined based on the orientation of the pair of pants.)

The pairs of pants are glued together according to the numbering of the bounding curves. For example, a boundary curve with number +3 and a boundary curve with number -3 result in an orientation-preserving gluing, since one pair of pants will be on the left and the other on the right side of curve 3. If two boundary curves both have number 3, then an orientation of the annulus neighborhood of the curve 3 is chosen, whose orientation agrees with the orientation of the pair of pants `P^+` on one side, but disagrees with the orientation of the pair of pants `P^-` on the other side. So from the perspective of the curve 3, there is a pair of pants on the left and there is one on the right.

If a boundary curve number does not have a pair, it is becomes a boundary component of the surface. Except when it appears in the `onesided_curves` array, in which case its opposite points are glued together, resulting in a one-sided curve in the surface.

The pairs of pants are implicitly `marked` by a triangle whose vertices are in different boundary components. So `[1, 2, 3]` is a different marking of the same pair of pants as `[1, 3, 2]`. However, `[2, 3, 1]` is the same marking as `[1, 2, 3]`. The marking `[1, 2, 3]` means that as the triangle is traversed in the counterclockwise order, we see the curves 1, 2, 3 in order.
"""
struct PantsDecomposition <: MarkedSurface
    region_to_separators::Vector{Tuple{Int16, Int16, Int16}}
    separator_to_region::Array{Int16, 2}
    separator_to_bdyindex::Array{BdyIndex, 2}
    numinnerpantscurves::Int16

    function PantsDecomposition(region_to_separators::Vector{Tuple{Int16, Int16, Int16}},
        separator_to_region::Array{Int16, 2}, 
        separator_to_bdyindex::Array{BdyIndex, 2},
        numinnerpantscurves::Int16)
        new(region_to_separators, separator_to_region, separator_to_bdyindex,
            numinnerpantscurves)
    end

    # gluinglist will not be copied, it is owned by the object
    function PantsDecomposition(gluinglist::Vector{<:Tuple{Int, Int, Int}})
        maxcurvenumber, numinnerpantscurves = check_gluinglist(gluinglist)

        separator_to_region, separator_to_bdyindex = 
            init_separator_arrays!(maxcurvenumber, gluinglist)
        new(gluinglist, separator_to_region, separator_to_bdyindex, numinnerpantscurves)
    end
end

TriMarking = Union{Triangulation, PantsDecomposition}


function isequal_strong(pd1::PantsDecomposition, pd2::PantsDecomposition)
    pd1.region_to_separators == pd2.region_to_separators && 
        pd1.separator_to_region == pd2.separator_to_region &&
        pd1.separator_to_bdyindex == pd2.separator_to_bdyindex
end


Base.copy(pd::PantsDecomposition) = PantsDecomposition(copy(pd.region_to_separators), 
    copy(pd.separator_to_region), copy(pd.separator_to_bdyindex), pd.numinnerpantscurves)

gluinglist(m::TriMarking) = m.region_to_separators
region_to_separators(m::TriMarking, region::Integer) = m.region_to_separators[region]

separators(m::TriMarking) = 1:numseparators(m)
regions(m::TriMarking) = 1:length(m.region_to_separators)
numregions(m::TriMarking) = length(m.region_to_separators)
numseparators(m::TriMarking) = size(m.separator_to_region)[2]

eulerchar(pd::PantsDecomposition) = -1*numregions(pd)
eulerchar(t::Triangulation) = numregions(t) - numseparators(t)



function _setseparatorside!(m::TriMarking, separator::Integer,
    side::Side, region::Integer, bdyindex::BdyIndex)
    if separator < 0
        side = otherside(side)
    end
    m.separator_to_region[Int(side), abs(separator)] = region
    m.separator_to_bdyindex[Int(side), abs(separator)] = bdyindex
end

function _set_regionboundaries!(m::TriMarking, region::Integer, bdy1::Integer, bdy2::Integer, bdy3::Integer)
    m.region_to_separators[region] = (bdy1, bdy2, bdy3)
end

separator_to_region(m::TriMarking, separator::Integer, side::Side=LEFT) = 
    m.separator_to_region[Int(separator > 0 ? side : otherside(side)), abs(separator)]

separator_to_bdyindex(m::TriMarking, separator::Integer, side::Side=LEFT) = 
    m.separator_to_bdyindex[Int(separator > 0 ? side : otherside(side)), abs(separator)]

region_to_separator(m::TriMarking, region::Integer, bdyindex::BdyIndex) = 
    m.region_to_separators[region][Int(bdyindex)]


const BDYCURVE = 1
const TORUS_NBHOOD = 2
const PUNCTURED_SPHERE_NBHOOD = 3

function pantscurve_type(pd::PantsDecomposition, curveindex::Integer)
    leftpant = separator_to_region(pd, curveindex, LEFT)
    rightpant = separator_to_region(pd, curveindex, RIGHT)
    if leftpant == 0 || rightpant == 0 
        return BDYCURVE
    end
    if leftpant != rightpant
        return PUNCTURED_SPHERE_NBHOOD
    else
        return TORUS_NBHOOD
    end
end

isinner_pantscurve(pd::PantsDecomposition, curveindex::Integer) = 
    pantscurve_type(pd, curveindex) != BDYCURVE
isboundary_pantscurve(pd::PantsDecomposition, curveindex::Integer) = 
    pantscurve_type(pd, curveindex) == BDYCURVE

isfirstmove_curve(pd::PantsDecomposition, curveindex::Integer) = 
    pantscurve_type(pd, curveindex) == TORUS_NBHOOD
issecondmove_curve(pd::PantsDecomposition, curveindex::Integer) = 
    pantscurve_type(pd, curveindex) == PUNCTURED_SPHERE_NBHOOD

innercurves(pd::PantsDecomposition) = 1:pd.numinnerpantscurves
# filter(x -> isinner_pantscurve(pd, x), separators(pd))
boundarycurves(pd::PantsDecomposition) = pd.numinnerpantscurves+1:size(pd.separator_to_region)[2]
numboundarycurves(pd::PantsDecomposition) = length(boundarycurves(pd))
numpunctures(pd::PantsDecomposition) = numboundarycurves(pd)



printed_text(pd::PantsDecomposition) = "PantsDecomposition with gluing list ["
printed_text(t::Triangulation) = "Triangulation with gluing list ["

function Base.show(io::IO, m::TriMarking)
    print(io, printed_text(m))
    for ls in gluinglist(m)
        print(io, "[$(ls[1]), $(ls[2]), $(ls[3])]")
    end
    print(io, "]")
end


function pantsdecomposition_humphries(genus::Integer)
    a = [(1, 2, -1)]
    for i in 1:genus-2
        push!(a, (3*i+1, 3*i, 1-3*i))
        push!(a, (-3*i, -1-3*i, 2+3*i))
    end
    push!(a, (-3*genus+3, -3*genus+4, 3*genus-3))
    PantsDecomposition(a)
end

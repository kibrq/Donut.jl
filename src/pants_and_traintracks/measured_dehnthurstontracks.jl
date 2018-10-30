module MeasuredDehnThurstonTracks

export measured_dehnthurstontrack

using Donut.Pants
using Donut.Pants.DTCoordinates
using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.PantsAndTrainTracks.DehnThurstonTracks
using Donut.PantsAndTrainTracks.DehnThurstonTracks: BranchData
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.Utils: nextindex, previndex
using Donut.Constants: LEFT, RIGHT

function divide_by_2(x::Integer)
    if x % 2 == 1
        error("The specified coordinates do not result in an integral lamination: an odd number is divided by 2.")
    end
    div(x, 2)
end

function divide_by_2(x::AbstractFloat)
    x/2
end

function selfconn_and_bridge_measures(ints1::T, ints2::T, ints3::T) where {T}
    ints = (ints1, ints2, ints3)
    selfconn = [divide_by_2(max(ints[i] - ints[nextindex(i, 3)] - ints[previndex(i, 3)], 0)) for i in 1:3]

    # take out the self-connecting strands, now the triangle ineq. is
    # satisfied
    adjusted_measures = Tuple(ints[i] - 2*selfconn[i] for i in 1:3)
    bridges = [divide_by_2(max(adjusted_measures[previndex(i, 3)] + adjusted_measures[nextindex(i, 3)] - adjusted_measures[i], 0)) for i in 1:3]
    return selfconn, bridges
end

"""
From the Dehn-Thurston coordinates, creates an array whose i'th element is the intersection number of the i'th pants curve. (Boundary pants curves are also included in this array.)
"""
function allcurve_intersections(pd::PantsDecomposition, intersection_numbers::Vector{T}) where {T}
    curves = curveindices(pd)
    len = maximum(curves)
    allintersections = fill(zero(T), len)
    innerindices = innercurveindices(pd)
    if length(innerindices) != length(intersection_numbers)
        error("Mismatch between number of inner pants curves ($(length(innerindices))) and the number of Dehn-Thurston coordinates ($(length(intersection_numbers))).")
    end
    for i in eachindex(innerindices)
        allintersections[innerindices[i]] = intersection_numbers[i]
    end
    return allintersections
end


function determine_measure(dttraintrack::TrainTrack, twisting_numbers::Vector{T}, selfconn_and_bridge_measures, branchdata::Vector{BranchData}) where {T}
    measure = T[]
    for br in eachindex(twisting_numbers)
        # println("Pantscurve")
        push!(measure, abs(twisting_numbers[br]))
        @assert branchdata[br].branchtype == PANTSCURVE
    end
    for br in length(twisting_numbers)+1:length(branchdata)
        data = branchdata[br]
        if data.branchtype == BRIDGE
            # println("Bridge")

            push!(measure, selfconn_and_bridge_measures[data.pantindex][2][data.bdyindex])
        elseif data.branchtype == SELFCONN
            # println("Selfconn")

            push!(measure, selfconn_and_bridge_measures[data.pantindex][1][data.bdyindex])
        else
            @assert false
        end
    end
    Measure{T}(dttraintrack, measure)
end


function determine_panttype(pd::PantsDecomposition, bdycurves, selfconn, bridges)
    # if at all possible, we include a self-connecting curve
    # first we check if there is a positive self-connecting measure in
    # which case the choice is obvious
    for i in 1:3
        if selfconn[i] > 0
            return i
        end
    end

    # If the value is self_conn_idx is still not determined, we see if the pairing measures allow including a self-connecting branch
    for i in 1:3
        curve = bdycurves[i]
        # making sure the opposite pair has zero measure
        if bridges[i] == 0 && isinner_pantscurve(pd, curve) && pant_nextto_pantscurve(pd, curve, LEFT) != pant_nextto_pantscurve(pd, curve, RIGHT) 
            # if the type is first move, then the self-connecting
            # branch would make the train track not recurrent
            return i
        end
    end
    return 0
end



function measured_dehnthurstontrack(pd::PantsDecomposition, dtcoords::DehnThurstonCoordinates)
    allintersections = allcurve_intersections(pd, dtcoords.intersection_numbers)
 
    sb_measures = [selfconn_and_bridge_measures([allintersections[abs(c)] for c in pantboundaries(pd, pant)]...) for pant in pants(pd)]
    
    pantstypes = [determine_panttype(pd, pantboundaries(pd, pant), sb_measures[pant]...) for pant in pants(pd)]

    turnings = [twist < 0 ? LEFT : RIGHT for twist in dtcoords.twisting_numbers]

    tt, encodings, branchdata = dehnthurstontrack(pd, pantstypes, turnings)

    measure = determine_measure(tt, dtcoords.twisting_numbers, sb_measures, branchdata)

    # encodings = branchencodings(tt, turnings, branchdata)

    tt, measure, encodings
end


function intersecting_measure(tt::TrainTrack, measure::Measure, branchencodings::Vector{ArcInPants}, sw::Int)
    x = 0
    for br in outgoing_branches(tt, sw)
        if !ispantscurve(branchencodings[abs(br)][1])
            x += branchmeasure(measure, br)
        end
    end
    x
end

function pantscurve_measure(tt::TrainTrack, measure::Measure, branchencodings::Vector{ArcInPants}, sw::Int)
    for br in outgoing_branches(tt, sw)
        if ispantscurve(branchencodings[abs(br)][1])
            return branchmeasure(measure, br)
        end
    end
end



end
module MeasuredDehnThurstonTracks

export measured_dehnthurstontrack, intersecting_measure, pantscurve_measure

using Donut.Pants
using Donut.Pants.DehnThurstonCoords
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

function selfconn_and_bridge_measures(ints::Tuple{T, T, T}) where {T}
    selfconn = (
        divide_by_2(max(ints[1] - ints[2] - ints[3], 0)),
        divide_by_2(max(ints[2] - ints[3] - ints[1], 0)),
        divide_by_2(max(ints[3] - ints[2] - ints[1], 0))
    )
    # take out the self-connecting strands, now the triangle ineq. is
    # satisfied
    adjusted_measures = (
        ints[1] - 2*selfconn[1],
        ints[2] - 2*selfconn[2],
        ints[3] - 2*selfconn[3]
    )
    bridges = (
        divide_by_2(max(adjusted_measures[3] + adjusted_measures[2] - adjusted_measures[1], 0)),
        divide_by_2(max(adjusted_measures[1] + adjusted_measures[3] - adjusted_measures[2], 0)),
        divide_by_2(max(adjusted_measures[2] + adjusted_measures[1] - adjusted_measures[3], 0))
    )
    return selfconn, bridges
end



function determine_measure(dttraintrack::TrainTrack, twisting_numbers, selfconn_and_bridge_measures, branchdata::Vector{BranchData})
    T = typeof(twisting_numbers[1])
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



function measured_dehnthurstontrack(pd::PantsDecomposition, dtcoords_vec::Vector{Tuple{T, T}}) where {T}
    dtcoords = DehnThurstonCoordinates{T}(pd, dtcoords_vec)
 
    sb_measures = Tuple(selfconn_and_bridge_measures(Tuple(intersection_number(dtcoords, c) for c in pantboundaries(pd, pant))) for pant in pants(pd))
    
    pantstypes = Tuple(determine_panttype(pd, pantboundaries(pd, pant), sb_measures[pant]...) for pant in pants(pd))

    twisting_numbers = Tuple(twisting_number(dtcoords, c) for c in innercurveindices(pd))
    turnings = Tuple(twist < 0 ? LEFT : RIGHT for twist in twisting_numbers)

    tt, encodings, branchdata = dehnthurstontrack(pd, pantstypes, turnings)

    measure = determine_measure(tt, twisting_numbers, sb_measures, branchdata)

    tt, measure, encodings
end


function intersecting_measure(tt::TrainTrack, measure::Measure, branchencodings::Vector{ArcInPants}, sw::Int)
    x = 0
    for br in outgoing_branches(tt, sw)
        if !ispantscurvearc(branchencodings[abs(br)])
            x += branchmeasure(measure, br)
        end
    end
    x
end


function pantscurve_measure(tt::TrainTrack, measure::Measure, branchencodings::Vector{ArcInPants}, sw::Int)
    for br in outgoing_branches(tt, sw)
        if ispantscurvearc(branchencodings[abs(br)])
            return branchmeasure(measure, br)
        end
    end
end



end


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



function determine_measure(dttraintrack::TrainTrack, 
        pd::PantsDecomposition, twisting_numbers, 
        selfconn_and_bridge_measures, branchencodings::Vector{Path{PantsArc}})
    T = typeof(twisting_numbers[1])
    measure_vector = T[]
    for br in eachindex(twisting_numbers)
        # println("Pantscurve")
        push!(measure_vector, abs(twisting_numbers[br]))
        @assert encoding_of_length1_branch(branchencodings, br) isa PantsCurveArc
    end
    for br in length(twisting_numbers)+1:length(branchencodings)
        arc = encoding_of_length1_branch(branchencodings, br)
        separator = signed_endvertex(arc)
        region = separator_to_region(pd, separator, LEFT)
        if arc isa BridgeArc
            bdyindex = bdyindex_of_bridge(pd, arc)
            push!(measure_vector, selfconn_and_bridge_measures[region][2][Int(bdyindex)])
        elseif arc isa SelfConnArc
            bdyindex = separator_to_bdyindex(pd, separator, LEFT)
            push!(measure_vector, selfconn_and_bridge_measures[region][1][Int(bdyindex)])
        else
            @assert false
        end
    end
    measure_vector
end

function bdyindex_of_bridge(pd::PantsDecomposition, arc::BridgeArc)
    sep1 = signed_endvertex(arc)
    sep2 = signed_startvertex(arc)
    bdyindex1 = separator_to_bdyindex(pd, sep1, LEFT)
    bdyindex2 = separator_to_bdyindex(pd, sep2, LEFT)
    x = (Int(bdyindex1) + Int(bdyindex2)) % 3
    if x == 0
        return BdyIndex(3)
    elseif x == 1
        return BdyIndex(2)
    else
        return BdyIndex(1)
    end
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
        if bridges[i] == 0 && isinner_pantscurve(pd, curve) && separator_to_region(pd, curve, LEFT) != separator_to_region(pd, curve, RIGHT) 
            # if the type is first move, then the self-connecting
            # branch would make the train track not recurrent
            return i
        end
    end
    return 0
end



function measured_dehnthurstontrack(pd::PantsDecomposition, 
        dtcoords_vec::Vector{Tuple{T, T}}) where {T}
    dtcoords = DehnThurstonCoordinates{T}(pd, dtcoords_vec)
 
    sb_measures = Tuple(selfconn_and_bridge_measures(Tuple(intersection_number(dtcoords, c) for c in region_to_separators(pd, pant))) for pant in regions(pd))
    
    pantstypes = Tuple(determine_panttype(pd, region_to_separators(pd, pant), sb_measures[pant]...) for pant in regions(pd))

    twisting_numbers = Tuple(twisting_number(dtcoords, c) for c in innercurves(pd))
    turnings = Tuple(twist < 0 ? LEFT : RIGHT for twist in twisting_numbers)

    tt, encodings = dehnthurstontrack(pd, pantstypes, turnings)

    measure_vector = determine_measure(tt, pd, twisting_numbers, sb_measures, encodings)
    add_measure!(tt, measure_vector)
    tt, encodings
end


function intersecting_measure(tt::TrainTrack, 
        branchencodings::Vector{Path{PantsArc}}, sw::Int)
    x = 0
    for br in outgoing_branches(tt, sw)
        if !(encoding_of_length1_branch(branchencodings, br) isa PantsCurveArc)
            x += branchmeasure(tt, br)
        end
    end
    x
end


function pantscurve_measure(tt::TrainTrack, 
        branchencodings::Vector{Path{PantsArc}}, sw::Int)
    for br in outgoing_branches(tt, sw)
        if encoding_of_length1_branch(branchencodings, br) isa PantsCurveArc
            return branchmeasure(tt, br)
        end
    end
end



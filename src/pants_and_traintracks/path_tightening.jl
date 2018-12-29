module PathTightening

using Donut.Constants
using Donut.Pants
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.ArcsInPants: gatetoside, selfconn_direction


export ispathtight, simplifypath!, reversedpath

function ispathtight(arc1::ArcInPants, arc2::ArcInPants)
    # println(arc1)
    # println(arc2)
    @assert endvertex(arc1) == startvertex(arc2)
    endgate(arc1) != startgate(arc2)
end


"""
Does not check subpaths of length 2.
"""
function ispathtight(arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
    # println(arc1)
    # println(arc2)
    # println(arc3)
    @assert endvertex(arc1) == startvertex(arc2)
    @assert endvertex(arc2) == startvertex(arc3)

    if !ispantscurvearc(arc2) || ispantscurvearc(arc1) || ispantscurvearc(arc3)
        return true
    end
    endgate(arc1) != startgate(arc3)
end



"""
Decide if a bridge goes from boundary i to i+1 (forward) or i+1 to i
(backward).
"""
function isbridgeforward(pd::PantsDecomposition, bridge::ArcInPants)
    @assert isbridge(bridge)
    startside = gatetoside(startgate(bridge))
    endside = gatetoside(endgate(bridge))
    index1 = bdyindex_nextto_pantscurve(pd, startvertex(bridge), startside)
    index2 = bdyindex_nextto_pantscurve(pd, endvertex(bridge), endside)
    @assert pant_nextto_pantscurve(pd, startvertex(bridge), startside) == pant_nextto_pantscurve(pd, endvertex(bridge), endside)

    if index2 == nextindex(index1)
        return true
    elseif index1 == nextindex(index2)
        return false
    else
        @assert false
    end
end

"""
Construct an arc along a pants curve.
"""
function pantscurvearc_lookingfromgate(pd::PantsDecomposition, signed_vertex::Int, side::Side)
    sign1 = side == LEFT ? 1 : -1
    # sign2 = ispantscurveside_orientationpreserving(pd, signed_vertex, LEFT) ? 1 : -1
    construct_pantscurvearc(signed_vertex * sign1)
end

# this could return an iterator for better speed
reversedpath(path::Vector{ArcInPants}) = [reversed(arc) for arc in reverse(path)]


function simplifiedpath(pd::PantsDecomposition, arc1::ArcInPants, arc2::ArcInPants)
    @assert !ispathtight(arc1, arc2)
    v0 = signed_startvertex(arc1)
    v1 = signed_endvertex(arc2)
    # println(g0, g1)
    # println(arc1)
    # println(arc2)

    # Backtracking
    if arc1 == reversed(arc2)
        return ArcInPants[]
    end

    if isbridge(arc1) && isbridge(arc2)
        return [construct_bridge(v0, v1)]
    end

    if isselfconnarc(arc1) && isbridge(arc2)
        # deciding if inward on outward
        if isbridgeforward(pd, arc2)
            # inward: FIGURE 2, 4
            return [construct_bridge(v0, v1),
                    pantscurvearc_lookingfromgate(pd, v1, selfconn_direction(arc1))]
        else
            # outward
            if selfconn_direction(arc1) == LEFT
                # FIGURE 4.5
                error("Simplification should first be somewhere else")
            else
                # FIGURE 3
                return [pantscurvearc_lookingfromgate(pd, v0, LEFT),
                        construct_bridge(v0, v1),
                        pantscurvearc_lookingfromgate(pd, v1, LEFT)]
            end
        end
    elseif isselfconnarc(arc2) && isbridge(arc1)
        return reversedpath(simplifiedpath(pd, reversed(arc2), reversed(arc1)))
    else
        @assert false
    end
end


function directionof_pantscurvearc(pd::PantsDecomposition, pantscurvearc::ArcInPants, lookingfrom_signedvertex::Int)
    for direction in (LEFT, RIGHT)
        arc = pantscurvearc_lookingfromgate(pd, lookingfrom_signedvertex, direction)
        if pantscurvearc == arc
            return direction
        end
    end
    @assert false
end


function simplifiedpath(pd::PantsDecomposition, 
        arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
    @assert !ispathtight(arc1, arc2, arc3)

    v0 = signed_startvertex(arc1)
    v1 = signed_endvertex(arc1)
    v2 = signed_endvertex(arc3)

    if !isbridge(arc1)
        return reversedpath(simplifiedpath(pd, reversed(arc3), reversed(arc2), reversed(arc1)))
    end

    if isbridge(arc3)
        if v0 != v2
            # Figure 5: V-shape (same result as for Figure 3)
            # println([pantscurvearc_lookingfromgate(pd, v0, g0, LEFT),
            # ArcInPants(v0, g0, v2, g2),
            # pantscurvearc_lookingfromgate(pd, v2, g2, LEFT)])
            # println(gluinglist(pd))
            # println(v0, g0)
            # println(arc1, arc2, arc3)
            if isbridgeforward(pd, arc1)
                return [pantscurvearc_lookingfromgate(pd, v0, LEFT),
                        construct_bridge(v0, v2),
                        pantscurvearc_lookingfromgate(pd, v2, LEFT)]
            else
                return [pantscurvearc_lookingfromgate(pd, v0, RIGHT),
                        construct_bridge(v0, v2),
                        pantscurvearc_lookingfromgate(pd, v2, RIGHT)]
            end
        else
            direction = directionof_pantscurvearc(pd, arc2, v1)
            if isbridgeforward(pd, arc1)
                # FIGURE 6
                return [construct_selfconnarc(v0, direction)]
            else
                # FIGURE 7
                if direction == RIGHT
                    return [construct_selfconnarc(v0, LEFT),
                            pantscurvearc_lookingfromgate(pd, v0, LEFT)]
                else
                    return [pantscurvearc_lookingfromgate(pd, v0, RIGHT),
                            construct_selfconnarc(v0, RIGHT)]
                end
            end
        end
    elseif isselfconnarc(arc3)
        if !isbridgeforward(pd, arc1)
            # FIGURE 8.1, 8.2
            error("Simplification should first be somewhere else")
        end
        if selfconn_direction(arc3) == LEFT
            # FIGURE 8.3
            error("Simplification should first be somewhere else")
        end

        # FIGURE 8
        return [pantscurvearc_lookingfromgate(pd, v0, LEFT), arc1]
    else
        @assert false
    end

end


function simplifypath!(pd::PantsDecomposition, path::Vector{ArcInPants})
    count = 0
    while count < 1000
        count += 1
        illegalturn_found = false
        for i in 1:length(path)-1
            if !ispathtight(path[i], path[i+1])
                illegalturn_found = true
                replacement = simplifiedpath(pd, path[i], path[i+1])
                splice!(path, i:i+1, replacement)
                break
            end
        end
        for i in 1:length(path)-2
            if !ispathtight(path[i], path[i+1], path[i+2])
                illegalturn_found = true
                replacement = simplifiedpath(pd, path[i], path[i+1], path[i+2])
                splice!(path, i:i+2, replacement)
                break
            end
        end
        if !illegalturn_found
            break
        end
    end
    if count == 1000
        error("Infinite loop when pulling a path tight.")
    end
end


end
using Donut.Constants: FORWARD, BACKWARD, LEFT, RIGHT

export ispathtight!, simplifypath!, reversedpath

function ispathtight(arc1::ArcInPants, arc2::ArcInPants)
    # println(arc1)
    # println(arc2)
    @assert arc1.endvertex == arc2.startvertex
    if arc1 == reversed(arc2)
        return false
    end
    arc1.endgate != arc2.startgate || (arc1 == arc2 && ispantscurve(arc1))
end


"""
Does not check subpaths of length 2.
"""
function ispathtight(arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
    # println(arc1)
    # println(arc2)
    # println(arc3)
    @assert arc1.endvertex == arc2.startvertex
    @assert arc2.endvertex == arc3.startvertex

    if !ispantscurve(arc2) || ispantscurve(arc1) || ispantscurve(arc3)
        return true
    end
    arc1.endgate != arc3.startgate
end


using Donut.Pants


"""
Decide if a bridge goes from boundary i to i+1 (forward) or i+1 to i
(backward).
"""
function isbridgeforward(pd::PantsDecomposition, bridge::ArcInPants)
    @assert isbridge(bridge)
    index1 = bdyindex_nextto_pantscurve(pd, bridge.startvertex, bridge.startgate)
    index2 = bdyindex_nextto_pantscurve(pd, bridge.endvertex, bridge.endgate)
    @assert pant_nextto_pantscurve(pd, bridge.startvertex, bridge.startgate) == pant_nextto_pantscurve(pd, bridge.endvertex, bridge.endgate)

    if index2 % 3 == (index1 + 1) % 3
        return true
    elseif index1 % 3 == (index2 + 1) % 3
        return false
    else
        @assert false
    end
end

"""
Construct an arc along a pants curve.
"""
function construct_pantscurvearc(pd::PantsDecomposition, vertex::Int,
    lookingfromgate::Int, direction::Int)
    wrapdirection = direction == lookingfromgate ? FORWARD : BACKWARD
    if !ispantscurveside_orientationpreserving(pd, vertex, lookingfromgate)
        wrapdirection = otherside(wrapdirection)
    end
    pantscurvearc(vertex, wrapdirection)
end

# this could return an iterator for better speed
reversedpath(path::Array{ArcInPants,1}) = [reversed(arc) for arc in reverse(path)]


function simplifiedpath(pd::PantsDecomposition, arc1::ArcInPants, arc2::ArcInPants)
    @assert !ispathtight(arc1, arc2)
    v0 = arc1.startvertex
    g0 = arc1.startgate
    v1 = arc2.endvertex
    g1 = arc2.endgate
    # println(g0, g1)
    # println(arc1)
    # println(arc2)

    # Backtracking
    if arc1 == reversed(arc2)
        return ArcInPants[]
    end

    if isbridge(arc1) && isbridge(arc2)
        return [ArcInPants(v0, g0, v1, g1)]
    end

    if isselfconnecting(arc1) && isbridge(arc2)
        # deciding if inward on outward
        if isbridgeforward(pd, arc2)
            # inward: FIGURE 2, 4
            return [ArcInPants(v0, g0, v1, g1),
                    construct_pantscurvearc(pd, v1, g1, arc1.direction)]
        else
            # outward
            if arc1.direction == LEFT
                # FIGURE 4.5
                error("Simplification should first be somewhere else")
            else
                # FIGURE 3
                return [construct_pantscurvearc(pd, v0, g0, LEFT),
                        ArcInPants(v0, g0, v1, g1),
                        construct_pantscurvearc(pd, v1, g1, LEFT)]
            end
        end
    elseif isselfconnecting(arc2) && isbridge(arc1)
        return reversedpath(simplifiedpath(pd, reversed(arc2), reversed(arc1)))
    else
        @assert false
    end
end


function directionof_pantscurvearc(pd::PantsDecomposition, pantscurvearc::ArcInPants, lookingfromgate::Int)
    for direction in (LEFT, RIGHT)
        arc = construct_pantscurvearc(pd, pantscurvearc.startvertex, lookingfromgate, direction)
        if pantscurvearc == arc
            return direction
        end
    end
    @assert false
end


function simplifiedpath(pd::PantsDecomposition, 
        arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
    @assert !ispathtight(arc1, arc2, arc3)

    v0 = arc1.startvertex
    g0 = arc1.startgate
    g1 = arc1.endgate
    v2 = arc3.endvertex
    g2 = arc3.endgate

    if !isbridge(arc1)
        return reversedpath(simplifiedpath(pd, reversed(arc3), reversed(arc2), reversed(arc1)))
    end

    if isbridge(arc3)
        if v0 != v2
            # Figure 5: V-shape (same result as for Figure 3)
            # println([construct_pantscurvearc(pd, v0, g0, LEFT),
            # ArcInPants(v0, g0, v2, g2),
            # construct_pantscurvearc(pd, v2, g2, LEFT)])
            # println(gluinglist(pd))
            # println(v0, g0)
            # println(arc1, arc2, arc3)
            if isbridgeforward(pd, arc1)
                return [construct_pantscurvearc(pd, v0, g0, LEFT),
                        ArcInPants(v0, g0, v2, g2),
                        construct_pantscurvearc(pd, v2, g2, LEFT)]
            else
                return [construct_pantscurvearc(pd, v0, g0, RIGHT),
                        ArcInPants(v0, g0, v2, g2),
                        construct_pantscurvearc(pd, v2, g2, RIGHT)]
            end
        else
            if isbridgeforward(pd, arc1)
                # FIGURE 6
                direction = directionof_pantscurvearc(pd, arc2, g1)
                return [selfconnarc(v0, g0, direction)]
            else
                # FIGURE 7
                return [selfconnarc(v0, g0, LEFT),
                        construct_pantscurvearc(pd, v0, g0, LEFT)]
            end
        end
    elseif isselfconnecting(arc3)
        if !isbridgeforward(pd, arc1)
            # FIGURE 8.1, 8.2
            error("Simplification should first be somewhere else")
        end
        if arc3.direction == LEFT
            # FIGURE 8.3
            error("Simplification should first be somewhere else")
        end

        # FIGURE 8
        return [construct_pantscurvearc(pd, v0, g0, LEFT), arc1]
    else
        @assert false
    end

end


function simplifypath!(pd::PantsDecomposition, path::Array{ArcInPants, 1})
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
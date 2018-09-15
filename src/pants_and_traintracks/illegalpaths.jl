


function ispathtight(arc1::ArcInPants, arc2::ArcInPants)
    @assert arc1.endvertex == arc2.startvertex
    if arc1 == reversed(arc2)
        return false
    end
    arc1.endgate != arc2.startgate
end


"""
Does not check subpaths of length 2.
"""
function ispathtight(arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
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
function isbridgeforward(pd, arc2)
    # inward: FIGURE 2, 4
    return [ArcInPants(v0, g0, v1, g1),
            (pd::PantsDecomposition, bridge::ArcInPants)
    @assert isbridge(bridge)
    index1 = pantend_nextto_pantscurve(pd, bridge.startvertex, bridge.startgate).bdyindex
    index2 = pantend_nextto_pantscurve(pd, bridge.endvertex, bridge.endgate).bdyindex
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


reversedpath(path::Array{ArcInPants,1}) = [reversed(arc) for arc in reverse(path)]


function simplifypath(pd::PantsDecomposition, arc1::ArcInPants, arc2::ArcInPants)
    @assert !ispathtight(arc1, arc2)
    v0 = arc1.startvertex
    g0 = arc2.startgate
    v1 = arc1.endvertex
    v2 = arc2.endgate

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
                    construct_pantscurvearc(v1, g1, arc1.direction)]
        else
            # outward
            if arc1.direction == LEFT
                # FIGURE 4.5
                error("Simplification should first be somewhere else")
            else
                # FIGURE 3
                return [construct_pantscurvearc(v0, g0, LEFT),
                        ArcInPants(v0, g0, v1, g1),
                        construct_pantscurvearc(v1, g2, LEFT)]
            end
        end
    elseif isselfconnecting(arc2) && isbridge(arc1)
        return reversedpath(simplifypath(pd, reversed(arc2), reversed(arc1)))
    else
        @assert false
    end
end


function directionof_pantscurvearc(pd, pantscurvearc::ArcInPants, lookingfromgate::Int)
    for direction in (LEFT, RIGHT)
        arc = construct_pantscurvearc(pd, pantscurvearc.startvertex, lookingfromgate, direction)
        if pantscurvearc == arc
            return direction
        end
    end
    @assert false
end


function simplifypath(pd::PantsDecomposition, 
        arc1::ArcInPants, arc2::ArcInPants, arc3::ArcInPants)
    @assert !ispathtight(pd, arc1, arc2, arc3)

    v0 = arc1.startvertex
    g0 = arc1.startgate
    g1 = arc1.endgate
    v2 = arc3.endvertex
    g2 = arc3.endgate

    if !isbridge(arc1)
        return reversedpath(simplifypath(pd, reversed(arc3), reversed(arc2), reversed(arc1)))
    end

    if isbridge(arc3)
        if v0 != v2
            # Figure 5: V-shape (same result as for Figure 3)
            return [construct_pantscurvearc(v0, g0, LEFT),
                    ArcInPants(v0, g0, v2, g2),
                    construct_pantscurvearc(v2, v2, LEFT)]
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
        if !isbridgeforward(arc1)
            # FIGURE 8.1, 8.2
            error("Simplification should first be somewhere else")
        end
        if arc3.direction == LEFT
            # FIGURE 8.3
            error("Simplification should first be somewhere else")
        end

        # FIGURE 8
        return [construct_pantscurvearc(v0, g0, LEFT), arc1]
    else
        @assert false
    end

end



function simplifypath!(pd::PantsDecomposition, path::Array{ArcInPants, 1})

end
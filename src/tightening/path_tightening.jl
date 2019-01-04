




function ispathtight(arc1::PantsArc, arc2::PantsArc)
    @assert endvertex(arc1) == startvertex(arc2)
    endgate(arc1) != startgate(arc2)
end


"""
Does not check subpaths of length 2.
"""
function ispathtight(arc1::PantsArc, arc2::PantsArc, arc3::PantsArc)
    @assert endvertex(arc1) == startvertex(arc2)
    @assert endvertex(arc2) == startvertex(arc3)

    if !(arc2 isa PantsCurveArc) || arc1 isa PantsCurveArc || arc3 isa PantsCurveArc
        return true
    end
    endgate(arc1) != startgate(arc3)
end



"""
Decide if a bridge goes from boundary i to i+1 (forward) or i+1 to i
(backward).
"""
function isbridgeforward(m::TriMarking, bridge::BridgeArc)
    startside = gatetoside(startgate(bridge))
    endside = gatetoside(endgate(bridge))
    index1 = separator_to_bdyindex(m, startvertex(bridge), startside)
    index2 = separator_to_bdyindex(m, endvertex(bridge), endside)
    @assert separator_to_region(m, startvertex(bridge), startside) == 
        separator_to_region(m, endvertex(bridge), endside)

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
function pantscurvearc_lookingfromgate(pd::PantsDecomposition, signed_vertex::Integer, side::Side)
    sign1 = side == LEFT ? 1 : -1
    # sign2 = ispantscurveside_orientationpreserving(pd, signed_vertex, LEFT) ? 1 : -1
    PantsCurveArc(signed_vertex * sign1)
end

# # this could return an iterator for better speed
# reversedpath(path::Vector{PantsArc}) = PantsArc[reversed(arc) for arc in reverse(path)]

reverse_shortpath() = ()
reverse_shortpath(a) = (reverse(a),)
reverse_shortpath(a, b) = (reverse(b), reverse(a))
reverse_shortpath(a, b, c) = (reverse(c), reverse(b), reverse(a))

function simplifiedpath(t::Triangulation, arc1::BridgeArc, arc2::BridgeArc)
    @assert !ispathtight(arc1, arc2)
    if arc1 == reverse(arc2)
        return ()
    end

    v0 = signed_startvertex(arc1)
    v1 = signed_endvertex(arc2)
    return (BridgeArc(v0, v1),)
end

function simplifiedpath(pd::PantsDecomposition, arc1::PantsArc, arc2::PantsArc)
    @assert !ispathtight(arc1, arc2)
    v0 = signed_startvertex(arc1)
    v1 = signed_endvertex(arc2)
    # println(g0, g1)
    # println(arc1)
    # println(arc2)

    # Backtracking
    if arc1 == reverse(arc2)
        return ()
    end

    if arc1 isa BridgeArc && arc2 isa BridgeArc
        return (BridgeArc(v0, v1),)
    end

    if arc1 isa SelfConnArc && arc2 isa BridgeArc
        # deciding if inward on outward
        if isbridgeforward(pd, arc2)
            # inward: FIGURE 2, 4
            return (BridgeArc(v0, v1),
                    pantscurvearc_lookingfromgate(pd, v1, arc1.direction))
        else
            # outward
            if arc1.direction == LEFT
                # FIGURE 4.5
                error("Simplification should first be somewhere else")
            else
                # FIGURE 3
                return (pantscurvearc_lookingfromgate(pd, v0, LEFT),
                        BridgeArc(v0, v1),
                        pantscurvearc_lookingfromgate(pd, v1, LEFT))
            end
        end
    elseif arc2 isa SelfConnArc && arc1 isa BridgeArc
        return reverse_shortpath(simplifiedpath(pd, reverse(arc2), reverse(arc1))...)
    else
        @assert false
    end
end


function directionof_pantscurvearc(pd::PantsDecomposition, pantscurvearc::PantsCurveArc, 
        lookingfrom_signedvertex::Integer)
    for direction in (LEFT, RIGHT)
        arc = pantscurvearc_lookingfromgate(pd, lookingfrom_signedvertex, direction)
        if pantscurvearc == arc
            return direction
        end
    end
    @assert false
end


function simplifiedpath(pd::PantsDecomposition, 
        arc1::PantsArc, arc2::PantsArc, arc3::PantsArc)
    @assert !ispathtight(arc1, arc2, arc3)

    v0 = signed_startvertex(arc1)
    v1 = signed_endvertex(arc1)
    v2 = signed_endvertex(arc3)

    if !(arc1 isa BridgeArc)
        return reverse_shortpath(
            simplifiedpath(pd, reverse(arc3), reverse(arc2), reverse(arc1))...)
    end

    if arc3 isa BridgeArc
        if v0 != v2
            # Figure 5: V-shape (same result as for Figure 3)
            # println([pantscurvearc_lookingfromgate(pd, v0, g0, LEFT),
            # PantsArc(v0, g0, v2, g2),
            # pantscurvearc_lookingfromgate(pd, v2, g2, LEFT)])
            # println(gluinglist(pd))
            # println(v0, g0)
            # println(arc1, arc2, arc3)
            if isbridgeforward(pd, arc1)
                return (pantscurvearc_lookingfromgate(pd, v0, LEFT),
                        BridgeArc(v0, v2),
                        pantscurvearc_lookingfromgate(pd, v2, LEFT))
            else
                return (pantscurvearc_lookingfromgate(pd, v0, RIGHT),
                        BridgeArc(v0, v2),
                        pantscurvearc_lookingfromgate(pd, v2, RIGHT))
            end
        else
            direction = directionof_pantscurvearc(pd, arc2, v1)
            if isbridgeforward(pd, arc1)
                # FIGURE 6
                return (SelfConnArc(v0, direction),)
            else
                # FIGURE 7
                if direction == RIGHT
                    return (SelfConnArc(v0, LEFT),
                            pantscurvearc_lookingfromgate(pd, v0, LEFT))
                else
                    return (pantscurvearc_lookingfromgate(pd, v0, RIGHT),
                            SelfConnArc(v0, RIGHT))
                end
            end
        end
    elseif arc3 isa SelfConnArc
        if !isbridgeforward(pd, arc1)
            # FIGURE 8.1, 8.2
            error("Simplification should first be somewhere else")
        end
        if arc3.direction == LEFT
            # FIGURE 8.3
            error("Simplification should first be somewhere else")
        end

        # FIGURE 8
        return (pantscurvearc_lookingfromgate(pd, v0, LEFT), arc1,)
    else
        @assert false
    end

end



function find_and_simplify_length2!(m::TriMarking, path)
    for i in 1:length(path)-1
        if !ispathtight(path[i], path[i+1])
            replacement = simplifiedpath(m, path[i], path[i+1])
            splice!(path, i:i+1, replacement)
            return true
        end
    end
    return false
end

function find_and_simplify_length3!(pd::PantsDecomposition, path)
    for i in 1:length(path)-2
        if !ispathtight(path[i], path[i+1], path[i+2])
            replacement = simplifiedpath(pd, path[i], path[i+1], path[i+2])
            splice!(path, i:i+2, replacement)
            return true
        end
    end
    return false
end

function find_and_simplify!(pd::PantsDecomposition, path)
    illegalturn_found = find_and_simplify_length2!(pd, path)
    if illegalturn_found
        return true
    end
    illegalturn_found = find_and_simplify_length3!(pd, path)
    return illegalturn_found
end

function find_and_simplify!(t::Triangulation, path)
    illegalturn_found = find_and_simplify_length2!(pd, path)
    return illegalturn_found
end

function simplifypath!(m::TriMarking, path)
    count = 0
    while count < 1000
        count += 1
        illegalturn_found = find_and_simplify!(m, path)
        if !illegalturn_found
            break
        end
    end
    if count == 1000
        error("Infinite loop when pulling a path tight.")
    end
end

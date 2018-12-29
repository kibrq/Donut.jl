

module ArcsInPants

export ArcInPants, isbridge, ispantscurvearc, isselfconnarc, signed_startvertex, 
    signed_endvertex, startvertex, endvertex, startgate, endgate, construct_bridge, 
    construct_pantscurvearc, construct_selfconnarc, BRIDGE, PANTSCURVE, SELFCONN, 
    reversed, PantsArcType


using Donut.Constants

@enum PantsArcType::Int8 PANTSCURVE SELFCONN BRIDGE
@enum PantsGate::Int8 LEFTGATE = 1 RIGHTGATE = -1 FORWARDGATE = 2 BACKWARDGATE = -2


"""
    For a self-connecting arc, the direction is LEFT is the arc starts on the left and returns on the right (i.e. the arc goes around in the clockwise direction)
"""


struct ArcInPants
    type::PantsArcType
    gate::Int
    extrainfo::Int
end
# Pantscurve: 3 vs -3
# Selfconn: 3, LEFT vs 3, RIGHT
# Bridge: 4, -3

construct_pantscurvearc(curveindex::Int) = ArcInPants(PANTSCURVE, curveindex, 0)

construct_bridge(startgate::Int, endgate::Int) = ArcInPants(BRIDGE, startgate, endgate)

construct_selfconnarc(gate::Int, direction::Side) = 
    ArcInPants(SELFCONN, gate, Int(direction))

function Base.show(io::IO, arc::ArcInPants)
    if arc.type == PANTSCURVE
        str = "Pantscurve($(arc.gate))"
    elseif arc.type == BRIDGE
        str = "Bridge($(arc.gate), $(arc.extrainfo))"
    else            
        str = "Selfconn($(arc.gate), $(Side(arc.extrainfo) == LEFT ? "LEFT" : "RIGHT"))" 
    end
    print(io, str)
end

function reversed(arc::ArcInPants)
    if arc.type == PANTSCURVE
        return construct_pantscurvearc(-arc.gate)
    elseif arc.type == BRIDGE
        return construct_bridge(arc.extrainfo, arc.gate)
    elseif arc.type == SELFCONN
        return construct_selfconnarc(arc.gate, otherside(selfconn_direction(arc)))
    else
        @assert false
    end
end


isbridge(arc::ArcInPants) = arc.type == BRIDGE
ispantscurvearc(arc::ArcInPants) = arc.type == PANTSCURVE
isselfconnarc(arc::ArcInPants) = arc.type == SELFCONN

startvertex(arc::ArcInPants) = abs(arc.gate)
endvertex(arc::ArcInPants) = isbridge(arc) ? abs(arc.extrainfo) : startvertex(arc)


function signed_startvertex(arc::ArcInPants)::Int
    arc.gate
end

function signed_endvertex(arc::ArcInPants)::Int
    if isbridge(arc)
        arc.extrainfo
    elseif isselfconnarc(arc)
        arc.gate
    elseif ispantscurvearc(arc)
        -arc.gate
    else
        @assert false
    end
end
    

# Gates for Pantscurves are FORWARDGATE (2) or BACKWARDGATE (-2).
# Gates for Bridges and Selfconns are LEFTGATE (1) or RIGHTGATE (-1)
function startgate(arc::ArcInPants)::PantsGate
    if ispantscurvearc(arc) 
        return arc.gate > 0 ? FORWARDGATE : BACKWARDGATE
    else
        return arc.gate > 0 ? LEFTGATE : RIGHTGATE
    end
end

function endgate(arc::ArcInPants)::PantsGate
    if ispantscurvearc(arc)
        return arc.gate > 0 ? BACKWARDGATE : FORWARDGATE
    elseif isbridge(arc)
        return arc.extrainfo > 0 ? LEFTGATE : RIGHTGATE
    elseif isselfconnarc(arc)
        return arc.gate > 0 ? LEFTGATE : RIGHTGATE
    end
end


function selfconn_direction(arc::ArcInPants)::Side
    @assert isselfconnarc(arc)
    Side(arc.extrainfo)
end

function pantscurvearc_direction(arc::ArcInPants)::ForwardOrBackward
    @assert ispantscurvearc(arc)
    return arc.gate > 0 ? FORWARD : BACKWARD
end

function gatetoside(gate::PantsGate)::Side
    if gate == LEFTGATE
        return LEFT
    elseif gate == RIGHTGATE
        return RIGHT
    else
        @assert false
    end
end


end
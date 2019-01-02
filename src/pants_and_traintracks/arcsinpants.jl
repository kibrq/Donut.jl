

module ArcsInPants

export ArcInPants, BridgeArc, PantsCurveArc, SelfConnArc, signed_startvertex, 
    signed_endvertex, startvertex, endvertex, startgate, endgate,  
    reverse, PantsArcType, PANTSCURVE, SELFCONN, BRIDGE, direction_of_pantscurvearc

using Donut.Constants


# Gates for Pantscurves are FORWARDGATE (2) or BACKWARDGATE (-2).
# Gates for Bridges and Selfconns are LEFTGATE (1) or RIGHTGATE (-1)
@enum PantsGate::Int8 LEFTGATE = 1 RIGHTGATE = -1 FORWARDGATE = 2 BACKWARDGATE = -2

@enum PantsArcType::Int8 PANTSCURVE SELFCONN BRIDGE


"""
    For a self-connecting arc, the direction is LEFT is the arc starts on the left and returns on the right (i.e. the arc goes around in the clockwise direction)
"""

# abstract type ArcInPants end

struct BridgeArc
    startgate::Int16
    endgate::Int16
end

function Base.show(io::IO, arc::BridgeArc)
    print(io, "Bridge($(arc.startgate), $(arc.endgate))")
end

Base.reverse(arc::BridgeArc) = BridgeArc(arc.endgate, arc.startgate)
signed_startvertex(arc::BridgeArc) = arc.startgate
signed_endvertex(arc::BridgeArc) = arc.endgate
startgate(arc::BridgeArc) = arc.startgate > 0 ? LEFTGATE : RIGHTGATE
endgate(arc::BridgeArc) = arc.endgate > 0 ? LEFTGATE : RIGHTGATE

struct PantsCurveArc 
    curveindex::Int16
end

function Base.show(io::IO, arc::PantsCurveArc)
    print(io, "Pantscurve($(arc.curveindex))")
end

Base.reverse(arc::PantsCurveArc) = PantsCurveArc(-arc.curveindex)
signed_startvertex(arc::PantsCurveArc) = arc.curveindex
signed_endvertex(arc::PantsCurveArc) = -arc.curveindex
startgate(arc::PantsCurveArc) = arc.curveindex > 0 ? FORWARDGATE : BACKWARDGATE
endgate(arc::PantsCurveArc) = arc.curveindex > 0 ? BACKWARDGATE : FORWARDGATE
direction_of_pantscurvearc(arc::PantsCurveArc) = arc.curveindex > 0 ? FORWARD : BACKWARD

struct SelfConnArc 
    gate::Int16
    direction::Side
end

function Base.show(io::IO, arc::SelfConnArc)
    print(io, "Selfconn($(arc.gate), $(arc.direction))" )
end

Base.reverse(arc::SelfConnArc) = SelfConnArc(arc.gate, otherside(arc.direction))
signed_startvertex(arc::SelfConnArc) = arc.gate
signed_endvertex(arc::SelfConnArc) = arc.gate
startgate(arc::SelfConnArc) = arc.gate > 0 ? LEFTGATE : RIGHTGATE
endgate(arc::SelfConnArc) = arc.gate > 0 ? LEFTGATE : RIGHTGATE

ArcInPants = Union{BridgeArc, SelfConnArc, PantsCurveArc}

startvertex(arc::ArcInPants) = abs(signed_startvertex(arc))
endvertex(arc::ArcInPants) = abs(signed_endvertex(arc))


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


module ArcsInPants

export ArcInPants, isbridge, ispantscurvearc, isselfconnarc, signed_startvertex, signed_endvertex, startvertex, endvertex, startgate, endgate, construct_bridge, construct_pantscurvearc, construct_selfconnarc, BRIDGE, PANTSCURVE, SELFCONN, reversed

using Donut.Utils: otherside
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

const PANTSCURVE = 1
const SELFCONN = 2
const BRIDGE = 3


"""
    For a self-connecting arc, the direction is LEFT is the arc starts on the left and returns on the right (i.e. the arc goes around in the clockwise direction)
"""


struct ArcInPants
    type::Int
    gate::Int
    extrainfo::Int
end
# Pantscurve: 3 vs -3
# Selfconn: 3, LEFT vs 3, RIGHT
# Bridge: 4, -3

construct_pantscurvearc(curveindex::Int) = ArcInPants(PANTSCURVE, curveindex, 0)

construct_bridge(startgate::Int, endgate::Int) = ArcInPants(BRIDGE, startgate, endgate)

construct_selfconnarc(gate::Int, direction::Int) = ArcInPants(SELFCONN, gate, direction)

function Base.show(io::IO, arc::ArcInPants)
    if arc.type == PANTSCURVE
        str = "Pantscurve($(arc.gate))"
    elseif arc.type == BRIDGE
        str = "Bridge($(arc.gate), $(arc.extrainfo))"
    else        
        str = "Selfconn($(arc.gate), $(arc.extrainfo == LEFT ? "LEFT" : "RIGHT"))" 
    end
    print(io, str)
end

function reversed(arc::ArcInPants)
    if arc.type == PANTSCURVE
        return construct_pantscurvearc(-arc.gate)
    elseif arc.type == BRIDGE
        return construct_bridge(arc.extrainfo, arc.gate)
    elseif arc.type == SELFCONN
        return construct_selfconnarc(arc.gate, otherside(arc.extrainfo))
    else
        @assert false
    end
end


isbridge(arc::ArcInPants) = arc.type == BRIDGE
ispantscurvearc(arc::ArcInPants) = arc.type == PANTSCURVE
isselfconnarc(arc::ArcInPants) = arc.type == SELFCONN

startvertex(arc::ArcInPants) = abs(arc.gate)
endvertex(arc::ArcInPants) = isbridge(arc) ? abs(arc.extrainfo) : startvertex(arc)


function signed_startvertex(arc::ArcInPants)
    arc.gate
end

function signed_endvertex(arc::ArcInPants)
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
    

const LEFTGATE = 1
const RIGHTGATE = -1
const FORWARDGATE = 2
const BACKWARDGATE = -2

# Gates for Pantscurves are FORWARDGATE (2) or BACKWARDGATE (-2).
# Gates for Bridges and Selfconns are LEFTGATE (1) or RIGHTGATE (-1)
function startgate(arc::ArcInPants) 
    if ispantscurvearc(arc) 
        return arc.gate > 0 ? FORWARDGATE : BACKWARDGATE
    else
        return sign(arc.gate)
    end
end

function endgate(arc::ArcInPants)
    if ispantscurvearc(arc)
        return arc.gate > 0 ? BACKWARDGATE : FORWARDGATE
    elseif isbridge(arc)
        return sign(arc.extrainfo)
    elseif isselfconnarc(arc)
        return sign(arc.gate)
    end
end


function selfconn_direction(arc::ArcInPants)
    @assert isselfconnarc(arc)
    arc.extrainfo
end

function pantscurvearc_direction(arc::ArcInPants)
    @assert ispantscurvearc(arc)
    return arc.gate > 0 ? FORWARD : BACKWARD
end

function gatetoside(gate::Int)
    if gate == LEFTGATE
        return LEFT
    elseif gate == RIGHTGATE
        return RIGHT
    else
        @assert false
    end
end


end
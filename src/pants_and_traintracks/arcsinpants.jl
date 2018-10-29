

module ArcsInPants


using Donut.Utils: otherside

const PANTSCURVE = 1
const SELFCONN = 2
const BRIDGE = 3


# const MIDDLE = 0

"""
    For a self-connecting arc, the direction is LEFT is the arc starts on the left and returns on the right (i.e. the arc goes around in the clockwise direction)
"""
# struct ArcInPants
#     startvertex::Int
#     startgate::Int
#     endvertex::Int
#     endgate::Int
#     direction::Int
#     # endcurves::Array{Int, 1}  # start curve, end curve
#     # gates::Array{Int, 1}  # start gate, end gate
# end

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



# ArcInPants(a, b, c, d) = ArcInPants(a, b, c, d, 0)

# pantscurvearc(vertex, direction) = ArcInPants(
    # vertex, MIDDLE, vertex, MIDDLE, direction
# )

# selfconnarc(vertex, gate, direction) = ArcInPants(
    # vertex, gate, vertex, gate, direction
# )

# function reversed(arc::ArcInPants)
#     newdirection = arc.direction == MIDDLE ? MIDDLE : otherside(arc.direction)
#     ArcInPants(arc.endvertex, arc.endgate, arc.startvertex, arc.startgate, newdirection)
# end

isbridge(arc::ArcInPants) = arc.type == BRIDGE
ispantscurvearc(arc:ArcInPants) = arc.type == PANTSCURVE
isselfconnarc(arc::ArcInPants) = arc.type == BRIDGE

startvertex(arc::ArcInPants) = abs(arc.gate)
endvertex(arc::ArcInPants) = isbridge(arc) ? abs(arc.extrainfo) : startvertex(arc)

# isbridge(arc::ArcInPants) = (arc.startvertex, arc.startgate) != (arc.endvertex, arc.endgate)

# function ispantscurve(arc::ArcInPants)
#     if arc.startgate == MIDDLE
#         @assert arc.endgate == MIDDLE
#         return true
#     end
#     false
# end


# isselfconnecting(arc::ArcInPants) = arc.startvertex == arc.endvertex && arc.startgate == arc.endgate && arc.startgate != MIDDLE
    

end

using Donut.Utils: otherside

const MIDDLE = 0

"""
    For a self-connecting arc, the direction is LEFT is the arc starts on the left and returns on the right (i.e. the arc goes around in the clockwise direction)
"""
struct ArcInPants
    startvertex::Int
    startgate::Int
    endvertex::Int
    endgate::Int
    direction::Int
    # endcurves::Array{Int, 1}  # start curve, end curve
    # gates::Array{Int, 1}  # start gate, end gate
end

ArcInPants(a, b, c, d) = ArcInPants(a, b, c, d, 0)

pantscurvearc(vertex, direction) = ArcInPants(
    vertex, MIDDLE, vertex, MIDDLE, direction
)

selfconnarc(vertex, gate, direction) = ArcInPants(
    vertex, gate, vertex, gate, direction
)

function reversed(arc::ArcInPants)
    newdirection = arc.direction == MIDDLE ? MIDDLE : otherside(arc.direction)
    ArcInPants(arc.endvertex, arc.endgate, arc.startvertex, arc.startgate, newdirection)
end


isbridge(arc::ArcInPants) = (arc.startvertex, arc.startgate) != (arc.endvertex, arc.endgate)

function ispantscurve(arc::ArcInPants)
    if arc.startgate == MIDDLE
        @assert arc.endgate == MIDDLE
        return true
    end
    false
end


isselfconnecting(arc::ArcInPants) = arc.startvertex == arc.endvertex && arc.startgate == arc.endgate && arc.startgate != MIDDLE
    


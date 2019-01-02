module ArcsTest

using Test
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

arc = BridgeArc(1, -3)
@test reverse(arc) == BridgeArc(-3, 1)

arc = PantsCurveArc(4)
@test reverse(arc) == PantsCurveArc(-4)

arc = SelfConnArc(3, RIGHT)
@test reverse(arc) == SelfConnArc(3, LEFT)


end
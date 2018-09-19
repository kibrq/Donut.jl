module ArcsTest

using Test
using Donut.PantsAndTrainTracks: ArcInPants, pantscurvearc, selfconnarc, reversed, isbridge, ispantscurve, isselfconnecting
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

arc = ArcInPants(1, LEFT, 3, RIGHT)
@test reversed(arc) == ArcInPants(3, RIGHT, 1, LEFT)
@test isbridge(arc)
@test !ispantscurve(arc)
@test !isselfconnecting(arc)

arc = pantscurvearc(4, FORWARD)
@test reversed(arc) == pantscurvearc(4, BACKWARD)
@test !isbridge(arc)
@test ispantscurve(arc)
@test !isselfconnecting(arc)

arc = selfconnarc(3, LEFT, RIGHT)
@test reversed(arc) == selfconnarc(3, LEFT, LEFT)
@test !isbridge(arc)
@test !ispantscurve(arc)
@test isselfconnecting(arc)


end
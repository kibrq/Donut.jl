module ArcsTest

using Test
using Donut.PantsAndTrainTracks.ArcsInPants: ArcInPants, construct_pantscurvearc, construct_selfconnarc, construct_bridge, reversed, isbridge, ispantscurvearc, isselfconnarc
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

arc = construct_bridge(1, -3)
@test reversed(arc) == construct_bridge(-3, 1)
@test isbridge(arc)
@test !ispantscurvearc(arc)
@test !isselfconnarc(arc)

arc = construct_pantscurvearc(4)
@test reversed(arc) == construct_pantscurvearc(-4)
@test !isbridge(arc)
@test ispantscurvearc(arc)
@test !isselfconnarc(arc)

arc = construct_selfconnarc(3, RIGHT)
@test reversed(arc) == construct_selfconnarc(3, LEFT)
@test !isbridge(arc)
@test !ispantscurvearc(arc)
@test isselfconnarc(arc)


end
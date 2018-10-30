module DehnThurstonTracksTest

using Test
using Donut.Pants
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD
using Donut.TrainTracks
using Donut.PantsAndTrainTracks.DehnThurstonTracks: dehnthurstontrack, pantscurve_toswitch, switch_turning, branches_at_pantend, findbranch, arc_in_pantsdecomposition 

using Donut.PantsAndTrainTracks.ArcsInPants: SELFCONN, BRIDGE, PANTSCURVE, construct_pantscurvearc, construct_selfconnarc, construct_bridge


pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
turnings = [LEFT, RIGHT, LEFT]
tt, encodings, branchdata = dehnthurstontrack(pd, [1, 0], turnings)

@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 8
@test switchvalence(tt, 2) == 5
@test switchvalence(tt, 3) == 5
@test numoutgoing_branches(tt, 1) == 3
@test numoutgoing_branches(tt, 2) == 2
@test numoutgoing_branches(tt, 3) == 3

@test pantscurve_toswitch(pd, 1) == 1
@test pantscurve_toswitch(pd, -1) == -1
@test pantscurve_toswitch(pd, 2) == 2
@test pantscurve_toswitch(pd, -2) == -2
@test pantscurve_toswitch(pd, 3) == 3
@test pantscurve_toswitch(pd, -3) == -3

@test switch_turning(tt, 1, encodings) == LEFT
@test switch_turning(tt, 2, encodings) == RIGHT
@test switch_turning(tt, 3, encodings) == LEFT

@test length(branches_at_pantend(tt, pd, 1, 1, encodings)) == 4
@test length(branches_at_pantend(tt, pd, 1, 2, encodings)) == 1
@test length(branches_at_pantend(tt, pd, 1, 3, encodings)) == 1
@test length(branches_at_pantend(tt, pd, 2, 1, encodings)) == 2
@test length(branches_at_pantend(tt, pd, 2, 2, encodings)) == 2
@test length(branches_at_pantend(tt, pd, 2, 3, encodings)) == 2

@test findbranch(tt, pd, 1, 1, SELFCONN, encodings) != nothing
@test findbranch(tt, pd, 1, 2, SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 1, 3, SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, 1, SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, 2, SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, 3, SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 1, 1, BRIDGE, encodings) == nothing
@test findbranch(tt, pd, 1, 2, BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 1, 3, BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, 1, BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, 2, BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, 3, BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 1, 1, PANTSCURVE, encodings) == 1
@test findbranch(tt, pd, 1, 2, PANTSCURVE, encodings) == 2
@test findbranch(tt, pd, 1, 3, PANTSCURVE, encodings) == 3
@test findbranch(tt, pd, 2, 1, PANTSCURVE, encodings) == -3
@test findbranch(tt, pd, 2, 2, PANTSCURVE, encodings) == -2
@test findbranch(tt, pd, 2, 3, PANTSCURVE, encodings) == -1

pd = PantsDecomposition([[1, 2, 3], [-2, -3, 4]])
# dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
# in the first pant, only 2 and 3 are inner pants curves
@test_throws ErrorException dehnthurstontrack(pd, [0, 1], [LEFT, LEFT])
@test_throws ErrorException dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [2, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [3, 1], [LEFT, LEFT])

pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
turnings = [RIGHT, LEFT, LEFT]
tt, encodings, branchdata = dehnthurstontrack(pd, [3, 1, 0], turnings)
@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 5
@test switchvalence(tt, 2) == 7
@test switchvalence(tt, 3) == 6
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, 2) == 3
@test numoutgoing_branches(tt, 3) == 3

@test pantscurve_toswitch(pd, 2) == 1
@test pantscurve_toswitch(pd, -2) == -1
@test pantscurve_toswitch(pd, 3) == 2
@test pantscurve_toswitch(pd, -3) == -2
@test pantscurve_toswitch(pd, 6) == 3
@test pantscurve_toswitch(pd, -6) == -3


@test switch_turning(tt, 1, encodings) == RIGHT
@test switch_turning(tt, 2, encodings) == LEFT
@test switch_turning(tt, 3, encodings) == LEFT

@test length(branches_at_pantend(tt, pd, 1, 2, encodings)) == 1
@test length(branches_at_pantend(tt, pd, 1, 3, encodings)) == 3
@test length(branches_at_pantend(tt, pd, 2, 1, encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, 1, encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, 2, encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, 3, encodings)) == 2






@testset "Constructing arcs in pants decompositions" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test arc_in_pantsdecomposition(pd, 1, 2, BRIDGE) == construct_bridge(3, 1)
    @test arc_in_pantsdecomposition(pd, 1, -2, BRIDGE) == construct_bridge(1, 3)
    @test arc_in_pantsdecomposition(pd, 2, 3, BRIDGE) == construct_bridge(-3, -2)
    @test arc_in_pantsdecomposition(pd, 2, -3, BRIDGE) == construct_bridge(-2, -3)

    @test arc_in_pantsdecomposition(pd, 1, 3, SELFCONN) == construct_selfconnarc(3, LEFT)
    @test arc_in_pantsdecomposition(pd, 1, -3, SELFCONN) == construct_selfconnarc(3, RIGHT)
    @test arc_in_pantsdecomposition(pd, 2, 1, SELFCONN) == construct_selfconnarc(-3, LEFT)
    @test arc_in_pantsdecomposition(pd, 2, -1, SELFCONN) == construct_selfconnarc(-3, RIGHT)

    @test arc_in_pantsdecomposition(pd, 1, 1, PANTSCURVE) == construct_pantscurvearc(1)
    @test arc_in_pantsdecomposition(pd, 1, -1, PANTSCURVE) == construct_pantscurvearc(-1)

    pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
    @test arc_in_pantsdecomposition(pd, 3, 1, BRIDGE) == construct_bridge(6, -6)
    @test arc_in_pantsdecomposition(pd, 3, -1, BRIDGE) == construct_bridge(-6, 6)

    @test arc_in_pantsdecomposition(pd, 3, 2, SELFCONN) == construct_selfconnarc(6, LEFT)
    @test arc_in_pantsdecomposition(pd, 3, 3, SELFCONN) == construct_selfconnarc(-6, LEFT)

    @test arc_in_pantsdecomposition(pd, 3, 2, PANTSCURVE) == construct_pantscurvearc(6)
    @test arc_in_pantsdecomposition(pd, 3, 3, PANTSCURVE) == construct_pantscurvearc(6)
end







end
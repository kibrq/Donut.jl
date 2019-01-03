module DehnThurstonTracksTest

using Test
using Donut.Pants
using Donut.Constants
using Donut.TrainTracks
using Donut.PantsAndTrainTracks.DehnThurstonTracks: dehnthurstontrack, pantscurve_toswitch, switch_turning, branches_at_pantend, findbranch, arc_in_pantsdecomposition 

using Donut.PantsAndTrainTracks.ArcsInPants


pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
turnings = [LEFT, RIGHT, LEFT]
tt, encodings = dehnthurstontrack(pd, [1, 0], turnings)

@test collect(switches(tt)) == [1, 2, 3]
@test numbranches(tt) == 9
@test switchvalence(tt, 1) == 8
@test switchvalence(tt, 2) == 5
@test switchvalence(tt, 3) == 5
@test numoutgoing_branches(tt, 1) == 3
@test numoutgoing_branches(tt, 2) == 2
@test numoutgoing_branches(tt, 3) == 3

@test pantscurve_toswitch(pd, tt, encodings, 1) == 1
@test pantscurve_toswitch(pd, tt, encodings,-1) == -1
@test pantscurve_toswitch(pd, tt, encodings,2) == 2
@test pantscurve_toswitch(pd, tt, encodings,-2) == -2
@test pantscurve_toswitch(pd, tt, encodings,3) == 3
@test pantscurve_toswitch(pd, tt, encodings,-3) == -3

@test switch_turning(tt, 1, encodings) == LEFT
@test switch_turning(tt, 2, encodings) == RIGHT
@test switch_turning(tt, 3, encodings) == LEFT

@test length(branches_at_pantend(tt, pd, 1, BdyIndex(1), encodings)) == 4
@test length(branches_at_pantend(tt, pd, 1, BdyIndex(2), encodings)) == 1
@test length(branches_at_pantend(tt, pd, 1, BdyIndex(3), encodings)) == 1
@test length(branches_at_pantend(tt, pd, 2, BdyIndex(1), encodings)) == 2
@test length(branches_at_pantend(tt, pd, 2, BdyIndex(2), encodings)) == 2
@test length(branches_at_pantend(tt, pd, 2, BdyIndex(3), encodings)) == 2

@test findbranch(tt, pd, 1, BdyIndex(1), SELFCONN, encodings) != nothing
@test findbranch(tt, pd, 1, BdyIndex(2), SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 1, BdyIndex(3), SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, BdyIndex(1), SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, BdyIndex(2), SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 2, BdyIndex(3), SELFCONN, encodings) == nothing
@test findbranch(tt, pd, 1, BdyIndex(1), BRIDGE, encodings) == nothing
@test findbranch(tt, pd, 1, BdyIndex(2), BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 1, BdyIndex(3), BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, BdyIndex(1), BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, BdyIndex(2), BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 2, BdyIndex(3), BRIDGE, encodings) != nothing
@test findbranch(tt, pd, 1, BdyIndex(1), PANTSCURVE, encodings) == 1
@test findbranch(tt, pd, 1, BdyIndex(2), PANTSCURVE, encodings) == 2
@test findbranch(tt, pd, 1, BdyIndex(3), PANTSCURVE, encodings) == 3
@test findbranch(tt, pd, 2, BdyIndex(1), PANTSCURVE, encodings) == -3
@test findbranch(tt, pd, 2, BdyIndex(2), PANTSCURVE, encodings) == -2
@test findbranch(tt, pd, 2, BdyIndex(3), PANTSCURVE, encodings) == -1

pd = PantsDecomposition([(3, 1, 2), (-1, -2, 4)])
# dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
# in the first pant, only 1 and 2 are inner pants curves
@test_throws ErrorException dehnthurstontrack(pd, [0, 1], [LEFT, LEFT])
@test_throws ErrorException dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [2, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [3, 1], [LEFT, LEFT])

pd = PantsDecomposition([(6, 1, 2), (-1, 4, 5), (-2, 3, -3)])
turnings = [RIGHT, LEFT, LEFT]
tt, encodings = dehnthurstontrack(pd, [3, 1, 0], turnings)
@test collect(switches(tt)) == [1, 2, 3]
@test numbranches(tt) == 9
@test switchvalence(tt, 1) == 5
@test switchvalence(tt, 2) == 7
@test switchvalence(tt, 3) == 6
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, 2) == 3
@test numoutgoing_branches(tt, 3) == 3

@test pantscurve_toswitch(pd, tt, encodings,1) == 1
@test pantscurve_toswitch(pd, tt, encodings,-1) == -1
@test pantscurve_toswitch(pd, tt, encodings,2) == 2
@test pantscurve_toswitch(pd, tt, encodings,-2) == -2
@test pantscurve_toswitch(pd, tt, encodings,3) == 3
@test pantscurve_toswitch(pd, tt, encodings,-3) == -3


@test switch_turning(tt, 1, encodings) == RIGHT
@test switch_turning(tt, 2, encodings) == LEFT
@test switch_turning(tt, 3, encodings) == LEFT

@test length(branches_at_pantend(tt, pd, 1, BdyIndex(2), encodings)) == 1
@test length(branches_at_pantend(tt, pd, 1, BdyIndex(3), encodings)) == 3
@test length(branches_at_pantend(tt, pd, 2, BdyIndex(1), encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, BdyIndex(1), encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, BdyIndex(2), encodings)) == 2
@test length(branches_at_pantend(tt, pd, 3, BdyIndex(3), encodings)) == 2






@testset "Constructing arcs in pants decompositions" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(2), false, BRIDGE) == BridgeArc(3, 1)
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(2), true, BRIDGE) == BridgeArc(1, 3)
    @test arc_in_pantsdecomposition(pd, 2, BdyIndex(3), false, BRIDGE) == BridgeArc(-3, -2)
    @test arc_in_pantsdecomposition(pd, 2, BdyIndex(3), true, BRIDGE) == BridgeArc(-2, -3)
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(3), false, SELFCONN) == SelfConnArc(3, LEFT)
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(3), true, SELFCONN) == SelfConnArc(3, RIGHT)
    @test arc_in_pantsdecomposition(pd, 2, BdyIndex(1), false, SELFCONN) == SelfConnArc(-3, LEFT)
    @test arc_in_pantsdecomposition(pd, 2, BdyIndex(1), true, SELFCONN) == SelfConnArc(-3, RIGHT)
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(1), false, PANTSCURVE) == PantsCurveArc(1)
    @test arc_in_pantsdecomposition(pd, 1, BdyIndex(1), true, PANTSCURVE) == PantsCurveArc(-1)

end







end
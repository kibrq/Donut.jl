module DehnThurstonTracksTest

using Test
using Donut
using Donut.Pants
using Donut.PantsAndTrainTracks
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD
using Donut.TrainTracks
using Donut.PantsAndTrainTracks: ispantscurve, isbridge, isselfconnecting, ArcInPants, selfconn_and_bridge_measures, pantscurve_toswitch, switch_turning, branches_at_pantend, findbranch, SELFCONN, BRIDGE, PANTSCURVE, arc_in_pantsdecomposition, peel_to_remove_illegalturns!, peel_fold_secondmove!
using Donut.Pants.DTCoordinates
using Donut.TrainTracks.Measures

pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
turnings = [LEFT, RIGHT, LEFT]
tt, branchdata = dehnthurstontrack(pd, [1, 0], turnings)

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

encoding = branchencodings(tt, turnings, branchdata)
@test switch_turning(tt, 1, encoding) == LEFT
@test switch_turning(tt, 2, encoding) == RIGHT
@test switch_turning(tt, 3, encoding) == LEFT

@test length(branches_at_pantend(tt, pd, 1, 1, encoding)) == 4
@test length(branches_at_pantend(tt, pd, 1, 2, encoding)) == 1
@test length(branches_at_pantend(tt, pd, 1, 3, encoding)) == 1
@test length(branches_at_pantend(tt, pd, 2, 1, encoding)) == 2
@test length(branches_at_pantend(tt, pd, 2, 2, encoding)) == 2
@test length(branches_at_pantend(tt, pd, 2, 3, encoding)) == 2

@test findbranch(tt, pd, 1, 1, SELFCONN, encoding) != nothing
@test findbranch(tt, pd, 1, 2, SELFCONN, encoding) == nothing
@test findbranch(tt, pd, 1, 3, SELFCONN, encoding) == nothing
@test findbranch(tt, pd, 2, 1, SELFCONN, encoding) == nothing
@test findbranch(tt, pd, 2, 2, SELFCONN, encoding) == nothing
@test findbranch(tt, pd, 2, 3, SELFCONN, encoding) == nothing
@test findbranch(tt, pd, 1, 1, BRIDGE, encoding) == nothing
@test findbranch(tt, pd, 1, 2, BRIDGE, encoding) != nothing
@test findbranch(tt, pd, 1, 3, BRIDGE, encoding) != nothing
@test findbranch(tt, pd, 2, 1, BRIDGE, encoding) != nothing
@test findbranch(tt, pd, 2, 2, BRIDGE, encoding) != nothing
@test findbranch(tt, pd, 2, 3, BRIDGE, encoding) != nothing
@test findbranch(tt, pd, 1, 1, PANTSCURVE, encoding) == 1
@test findbranch(tt, pd, 1, 2, PANTSCURVE, encoding) == 2
@test findbranch(tt, pd, 1, 3, PANTSCURVE, encoding) == 3
@test findbranch(tt, pd, 2, 1, PANTSCURVE, encoding) == -3
@test findbranch(tt, pd, 2, 2, PANTSCURVE, encoding) == -2
@test findbranch(tt, pd, 2, 3, PANTSCURVE, encoding) == -1

pd = PantsDecomposition([[1, 2, 3], [-2, -3, 4]])
# dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
# in the first pant, only 2 and 3 are inner pants curves
@test_throws ErrorException dehnthurstontrack(pd, [0, 1], [LEFT, LEFT])
@test_throws ErrorException dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [2, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [3, 1], [LEFT, LEFT])

pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
turnings = [RIGHT, LEFT, LEFT]
tt, branchdata = dehnthurstontrack(pd, [3, 1, 0], turnings)
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

encoding = branchencodings(tt, turnings, branchdata)

@test switch_turning(tt, 1, encoding) == RIGHT
@test switch_turning(tt, 2, encoding) == LEFT
@test switch_turning(tt, 3, encoding) == LEFT

@test length(branches_at_pantend(tt, pd, 1, 2, encoding)) == 1
@test length(branches_at_pantend(tt, pd, 1, 3, encoding)) == 3
@test length(branches_at_pantend(tt, pd, 2, 1, encoding)) == 2
@test length(branches_at_pantend(tt, pd, 3, 1, encoding)) == 2
@test length(branches_at_pantend(tt, pd, 3, 2, encoding)) == 2
@test length(branches_at_pantend(tt, pd, 3, 3, encoding)) == 2


@testset "Branch encodings" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    turnings = [LEFT, RIGHT, LEFT]
    tt, branchdata = dehnthurstontrack(pd, [1, 0], turnings)
    enc = branchencodings(tt, turnings, branchdata)
    @test all(ispantscurve(enc[i][1]) for i in 1:3)
end


selfconn, pairs = selfconn_and_bridge_measures(1, 4, 7)
@test selfconn == [0, 0, 1]
@test pairs == [4, 1, 0]

selfconn, pairs = selfconn_and_bridge_measures(13, 10, 7)
@test selfconn == [0, 0, 0]
@test pairs == [2, 5, 8]

# selfconn, pairs = selfconn_and_bridge_measures(1, 1, 1)
# @test selfconn == [0, 0, 0]
# @test pairs == [0.5, 0.5, 0.5]


@testset "Dehn-Thurston train track from coordinates" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([1, 4, 3], [-3, -4, 10])
    tt, measure, encoding = dehnthurstontrack(pd, dtcoords)

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([5, 4, 3], [5, 0, -99])
    tt, measure, encoding = dehnthurstontrack(pd, dtcoords)


    pd = PantsDecomposition([[1, 2, 3], [-3, 4, 5]])
    dtcoords = DehnThurstonCoordinates([4], [-3])
    tt, measure, encoding = dehnthurstontrack(pd, dtcoords)
    @test outgoing_branch(tt, 1, 1) == -outgoing_branch(tt, -1, 1)
    @test outgoing_branch(tt, 1, 2) == -outgoing_branch(tt, 1, 3)
    @test outgoing_branch(tt, -1, 2) == -outgoing_branch(tt, -1, 3)
    @test branchmeasure(measure, outgoing_branch(tt, 1, 1)) == 3
    @test branchmeasure(measure, outgoing_branch(tt, 1, 2)) == 2
    @test branchmeasure(measure, outgoing_branch(tt, -1, 2)) == 2
end


@testset "Constructing arcs in pants decompositions" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test arc_in_pantsdecomposition(pd, 1, 2, BRIDGE) == ArcInPants(3, LEFT, 1, LEFT)
    @test arc_in_pantsdecomposition(pd, 1, -2, BRIDGE) == ArcInPants(1, LEFT, 3, LEFT)
    @test arc_in_pantsdecomposition(pd, 2, 3, BRIDGE) == ArcInPants(3, RIGHT, 2, RIGHT)
    @test arc_in_pantsdecomposition(pd, 2, -3, BRIDGE) == ArcInPants(2, RIGHT, 3, RIGHT)

    @test arc_in_pantsdecomposition(pd, 1, 3, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(3, LEFT, LEFT)
    @test arc_in_pantsdecomposition(pd, 1, -3, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(3, LEFT, RIGHT)
    @test arc_in_pantsdecomposition(pd, 2, 1, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(3, RIGHT, LEFT)
    @test arc_in_pantsdecomposition(pd, 2, -1, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(3, RIGHT, RIGHT)

    @test arc_in_pantsdecomposition(pd, 1, 1, PANTSCURVE) == Donut.PantsAndTrainTracks.pantscurvearc(1, FORWARD)
    @test arc_in_pantsdecomposition(pd, 1, -1, PANTSCURVE) == Donut.PantsAndTrainTracks.pantscurvearc(1, BACKWARD)

    pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
    @test arc_in_pantsdecomposition(pd, 3, 1, BRIDGE) == ArcInPants(6, LEFT, 6, RIGHT)
    @test arc_in_pantsdecomposition(pd, 3, -1, BRIDGE) == ArcInPants(6, RIGHT, 6, LEFT)

    @test arc_in_pantsdecomposition(pd, 3, 2, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(6, LEFT, LEFT)
    @test arc_in_pantsdecomposition(pd, 3, 3, SELFCONN) == Donut.PantsAndTrainTracks.selfconnarc(6, RIGHT, LEFT)

    @test arc_in_pantsdecomposition(pd, 3, 2, PANTSCURVE) == Donut.PantsAndTrainTracks.pantscurvearc(6, FORWARD)
    @test arc_in_pantsdecomposition(pd, 3, 3, PANTSCURVE) == Donut.PantsAndTrainTracks.pantscurvearc(6, FORWARD)
end

function tt_and_encodings(pd, panttypes, turnings)
    tt, branchdata = dehnthurstontrack(pd, panttypes, turnings)
    encoding = branchencodings(tt, turnings, branchdata)
    # longencodings = [[enc] for enc in encoding]
    tt, encoding
end

@testset "Dehn twists" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_dehntwist!(tt, pd, 2, 1, LEFT, longencodings)
    @test gluinglist(pd) == [[1, 2, 3], [-3, -2, -1]]
    @test sum(length(item) for item in longencodings) == 11

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_dehntwist!(tt, pd, 1, 1, RIGHT, longencodings)
    @test gluinglist(pd) == [[1, 2, 3], [-3, -2, -1]]
    @test sum(length(item) for item in longencodings) == 13

end


@testset "Half twists" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_halftwist!(tt, pd, 2, 3, longencodings)
    @test gluinglist(pd) == [[1, 2, 3], [-2, -3, -1]]
    @test sum(length(item) for item in longencodings) == 12

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_halftwist!(tt, pd, 1, 1, longencodings)
    @test gluinglist(pd) == [[1, 3, 2], [-3, -2, -1]]
    @test sum(length(item) for item in longencodings) == 12 
end


@testset "First move" begin
    pd = PantsDecomposition([[1, -1, 2], [-2, 3, -3]])
    tt, longencodings = tt_and_encodings(pd, [3, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_firstmove!(tt, pd, 1, longencodings)
    @test gluinglist(pd) == [[1, -1, 2], [-2, 3, -3]]
    @test sum(length(item) for item in longencodings) == 12

    pd = PantsDecomposition([[1, -1, 2], [-2, 3, -3]])
    tt, longencodings = tt_and_encodings(pd, [3, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_firstmove!(tt, pd, 3, longencodings)
    @test gluinglist(pd) == [[1, -1, 2], [-2, 3, -3]]
    @test sum(length(item) for item in longencodings) == 10
end

@testset "Second move" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_secondmove!(tt, pd, 1, longencodings)
    @test gluinglist(pd) == [[1, 3, -3], [-1, -2, 2]]
    @test sum(length(item) for item in longencodings) == 13 

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    tt, longencodings = tt_and_encodings(pd, [1, 0], [LEFT, RIGHT, LEFT])
    update_encodings_after_secondmove!(tt, pd, 2, longencodings)
    @test gluinglist(pd) == [[2, 1, -1], [-2, -3, 3]]
    @test sum(length(item) for item in longencodings) == 17
end



@testset "Peel to remove illegal turns" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([1, 6, 3], [-3, -4, 10])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    update_encodings_after_dehntwist!(tt, pd, 1, 3, RIGHT, longencodings)
    @test sum(length(item) for item in longencodings) == 10
    # the switch was right turning before and we twist to right, so no illegal turns.
    peel_to_remove_illegalturns!(tt, pd, longencodings, measure, [3])
    @test sum(length(item) for item in longencodings) == 9

    # Same thing, but twisting left. Now there are no illegal turns.
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([1, 6, 3], [-3, -4, 10])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    update_encodings_after_dehntwist!(tt, pd, 1, 3, LEFT, longencodings)
    @test sum(length(item) for item in longencodings) == 10
    # the switch was right turning before and we twist to right, so no illegal turns.
    peel_to_remove_illegalturns!(tt, pd, longencodings, measure, [1, 2, 3])
    @test sum(length(item) for item in longencodings) == 10

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([1, 6, 3], [-3, -4, 10])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    update_encodings_after_secondmove!(tt, pd, 2, longencodings)
    @test sum(length(item) for item in longencodings) == 13
    # the switch was right turning before and we twist to right, so no illegal turns.
    peel_to_remove_illegalturns!(tt, pd, longencodings, measure, [1, 2, 3])
    # @test sum(length(item) for item in longencodings) == 15  # TODO: check that this is 16.

end

@testset "Peel-fold second move 1" begin
    pd = PantsDecomposition([[1, -1, 2], [-2, -3, 3]])
    dtcoords = DehnThurstonCoordinates([11, 14, 8], [-100, 20, 30])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    peel_fold_secondmove!(tt, measure, pd, 2, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [8, 8, 11, 11, 13, 13, 20, 37, 93]
    peel_fold_secondmove!(tt, measure, pd, 2, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 4, 7, 7, 7, 7, 20, 30, 100]
end

@testset "Peel-fold second move 2" begin
    pd = PantsDecomposition([[1, -1, 2], [-2, -3, 3]])
    dtcoords = DehnThurstonCoordinates([2, 20, 6], [1, -1, 14])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 1, 2, 2, 4, 6, 6, 8, 14]
    peel_fold_secondmove!(tt, measure, pd, 2, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
    peel_fold_secondmove!(tt, measure, pd, 2, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 1, 2, 2, 4, 6, 6, 8, 14]
end

@testset "Peel-fold second move 3" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    dtcoords = DehnThurstonCoordinates([2, 10, 6], [3, -11, 20])
    tt, measure, longencodings = dehnthurstontrack(pd, dtcoords)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
    peel_fold_secondmove!(tt, measure, pd, 3, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [2, 2, 3, 4, 10, 10, 14, 21, 22]
    peel_fold_secondmove!(tt, measure, pd, 3, longencodings)
    @test all(length(enc) == 1 for enc in longencodings)
    @test sort(measure.values[1:length(branches(tt))]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
end


end
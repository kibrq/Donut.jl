module DehnThurstonTracksTest

using Test
using Donut.Pants
using Donut.PantsAndTrainTracks
using Donut.Constants: LEFT, RIGHT
using Donut.TrainTracks
using Donut.PantsAndTrainTracks: ispantscurve, isbridge, isselfconnecting, ArcInPants, selfconn_and_bridge_measures
using Donut.Pants.DTCoordinates
using Donut.TrainTracks.Measures

pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
tt, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])

@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 8
@test switchvalence(tt, 2) == 5
@test switchvalence(tt, 3) == 5
@test numoutgoing_branches(tt, 1) == 3
@test numoutgoing_branches(tt, 2) == 2
@test numoutgoing_branches(tt, 3) == 3

pd = PantsDecomposition([[1, 2, 3], [-2, -3, 4]])
# dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
# in the first pant, only 2 and 3 are inner pants curves
@test_throws ErrorException dehnthurstontrack(pd, [0, 1], [LEFT, LEFT])
@test_throws ErrorException dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [2, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [3, 1], [LEFT, LEFT])

pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
tt, _ = dehnthurstontrack(pd, [3, 1, 0], [RIGHT, LEFT, LEFT])
@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 5
@test switchvalence(tt, 2) == 7
@test switchvalence(tt, 3) == 6
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, 2) == 3
@test numoutgoing_branches(tt, 3) == 3


@testset "Branch encodings" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    turnings = [LEFT, RIGHT, LEFT]
    tt, branchdata = dehnthurstontrack(pd, [1, 0], turnings)
    enc = branchencodings(tt, turnings, branchdata)
    @test all(ispantscurve(enc[i]) for i in 1:3)
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


end
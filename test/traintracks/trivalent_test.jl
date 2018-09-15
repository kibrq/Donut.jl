module TrivalentTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks.Trivalent
using Donut.Constants: LEFT, RIGHT

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
@test !is_branch_large(tt, 1)
@test !is_branch_large(tt, 2)
@test is_branch_large(tt, 3)


tt = TrainTrack([[1, 2], [-1, -2]])
@test !istrivalent(tt)

tt = TrainTrack([[1, 2], [3], [-3], [-1, -2]])
@test istrivalent(tt)


@testset "Trivalent splittings" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test_throws ErrorException split_trivalent!(tt, 1, LEFT)
    @test_throws ErrorException split_trivalent!(tt, 2, LEFT)

    split_trivalent!(tt, 3, LEFT)
    @test outgoing_branches(tt, 1) == [1]
    @test outgoing_branches(tt, -1) == [-3, -2]
    @test outgoing_branches(tt, 2) == [3, 2]
    @test outgoing_branches(tt, -2) == [-1]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    split_trivalent!(tt, 3, RIGHT)
    @test outgoing_branches(tt, 1) == [2]
    @test outgoing_branches(tt, -1) == [-1, -3]
    @test outgoing_branches(tt, 2) == [1, 3]
    @test outgoing_branches(tt, -2) == [-2]
end


end
module TrainTrainBasicsTest

using Test
using Donut.TrainTracks
using Donut.Constants: RIGHT


@test_throws ErrorException TrainTrack([[1, 2], [-2], [-1]])
@test_throws ErrorException TrainTrack([[1, 2], [2, -1]])
@test_throws ErrorException TrainTrack([[1, 2, -2, -1], Int[]])
@test_throws ErrorException TrainTrack([[1, 2], [-2]])
@test_throws ErrorException TrainTrack([[1, 2], [-2, -3]])
@test_throws ErrorException TrainTrack([[1, 2, -2], [-2, -1, 1]])


tt = TrainTrack([[1, 2], [-1, -2]])
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, -1) == 2

@test isswitch(tt, 1)
@test isswitch(tt, -1)
@test !isswitch(tt, 2)
@test !isswitch(tt, -2)
@test !isswitch(tt, 0)

@test switches(tt) == [1]

@test isbranch(tt, 1)
@test isbranch(tt, -1)
@test isbranch(tt, 2)
@test !isbranch(tt, 3)
@test !isbranch(tt, 0)


@test switchvalence(tt, 1) == 4
@test switchvalence(tt, -1) == 4

@test outgoing_branches(tt, 1) == [1, 2]
@test outgoing_branches(tt, -1) == [-1, -2]
@test outgoing_branches(tt, 1, RIGHT) == [2, 1]
@test outgoing_branches(tt, -1, RIGHT) == [-2, -1]

@test outgoing_branch(tt, 1, 1) == 1
@test outgoing_branch(tt, 1, 1, RIGHT) == 2
@test outgoing_branch(tt, 1, 2) == 2
@test outgoing_branch(tt, 1, 2, RIGHT) == 1
@test outgoing_branch(tt, -1, 1) == -1

@test outgoing_branch_index(tt, 1, 2) == 2
@test outgoing_branch_index(tt, 1, 2, RIGHT) == 1
@test outgoing_branch_index(tt, -1, -2) == 2
@test_throws ErrorException outgoing_branch_index(tt, -1, 2)

@test branch_endpoint(tt, 1) == -1
@test branch_endpoint(tt, -1) == 1
@test branch_endpoint(tt, 2) == -1
@test branch_endpoint(tt, -2) == 1


@testset "Trivalent" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test !is_branch_large(tt, 1)
    @test !is_branch_large(tt, 2)
    @test is_branch_large(tt, 3)

    tt = TrainTrack([[1, 2], [-1, -2]])
    @test !istrivalent(tt)

    tt = TrainTrack([[1, 2], [3], [-3], [-1, -2]])
    @test istrivalent(tt)
end

end





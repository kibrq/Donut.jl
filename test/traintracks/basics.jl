
using Donut: PlainTrainTrack

@test_throws ErrorException PlainTrainTrack([[1, 2], [-2], [-1]])
@test_throws ErrorException PlainTrainTrack([[1, 2], [2, -1]])
@test_throws ErrorException PlainTrainTrack([[1, 2, -2, -1], Int[]])
@test_throws ErrorException PlainTrainTrack([[1, 2], [-2]])
@test_throws ErrorException PlainTrainTrack([[1, 2], [-2, -3]])
@test_throws ErrorException PlainTrainTrack([[1, 2, -2], [-2, -1, 1]])


tt = PlainTrainTrack([[1, 2], [-1, -2]])
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, -1) == 2

@test isswitch(tt, 1)
@test isswitch(tt, -1)
@test !isswitch(tt, 2)
@test !isswitch(tt, -2)
@test !isswitch(tt, 0)

@test collect(switches(tt)) == [1]

@test isbranch(tt, 1)
@test isbranch(tt, -1)
@test isbranch(tt, 2)
@test !isbranch(tt, 3)
@test !isbranch(tt, 0)


@test switchvalence(tt, 1) == 4
@test switchvalence(tt, -1) == 4

@test collect(outgoing_branches(tt, 1)) == [1, 2]
@test collect(outgoing_branches(tt, -1)) == [-1, -2]
@test collect(outgoing_branches(tt, 1, RIGHT)) == [2, 1]
@test collect(outgoing_branches(tt, -1, RIGHT)) == [-2, -1]

@test extremal_branch(tt, 1) == 1
@test extremal_branch(tt, 1, RIGHT) == 2
@test extremal_branch(tt, -1, LEFT) == -1
@test extremal_branch(tt, -1, RIGHT) == -2

@test next_branch(tt, 1, LEFT) == 0
@test next_branch(tt, 1, RIGHT) == 2
@test next_branch(tt, 2, LEFT) == 1
@test next_branch(tt, 2, RIGHT) == 0
@test next_branch(tt, -1, LEFT) == 0
@test next_branch(tt, -1, RIGHT) == -2
@test next_branch(tt, -2, LEFT) == -1
@test next_branch(tt, -2, RIGHT) == 0

@test branch_endpoint(tt, 1) == -1
@test branch_endpoint(tt, -1) == 1
@test branch_endpoint(tt, 2) == -1
@test branch_endpoint(tt, -2) == 1


@testset "Trivalent" begin
    tt = PlainTrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test !is_branch_large(tt, 1)
    @test !is_branch_large(tt, 2)
    @test is_branch_large(tt, 3)

    tt = PlainTrainTrack([[1, 2], [-1, -2]])
    @test !istrivalent(tt)

    tt = PlainTrainTrack([[1, 2], [3], [-3], [-1, -2]])
    @test istrivalent(tt)
end






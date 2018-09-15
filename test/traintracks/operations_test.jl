module TrainTrackOperationsTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks.Operations
using Donut.TrainTracks.Operations: BranchPosition, BranchRange
using Donut
using Donut.Constants: LEFT, RIGHT

tt = TrainTrack([[1, 2], [-1, -2]])
Donut.TrainTracks.Operations._delete_branch!(tt, 1)
@test tt.branches[1].endpoint == Int[0, 0]
@test tt.branches[1].istwisted == false
@test !isbranch(tt, 1)

tt = TrainTrack([[1, 2], [-1, -2]])
Donut.TrainTracks.Operations._delete_switch!(tt, 1)
@test tt.switches[1].outgoing_branch_indices == [Int[], Int[]]
@test tt.switches[1].numoutgoing_branches == [0, 0]

tt = TrainTrack([[1, 2], [-1, -2]])
Donut.TrainTracks.Operations.delete_branch!(tt, 1)
@test outgoing_branches(tt, 1) == [2]
@test outgoing_branches(tt, -1) == [-2]
@test branches(tt) == [2]

tt = TrainTrack([[1, 2], [-1, -2]])
@test Donut.TrainTracks.Operations._find_new_switch_number!(tt) == 2

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
@test collapse_branch!(tt, 3) == 1  # switch 1 is removed
@test !isswitch(tt, 1)
@test switches(tt) == [2]
@test Donut.TrainTracks.Operations._find_new_switch_number!(tt) == 1

tt = TrainTrack([[1, 2], [-1, -2]])
@test Donut.TrainTracks.Operations._find_new_branch_number!(tt) == 3

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
collapse_branch!(tt, 2)
@test Donut.TrainTracks.Operations._find_new_branch_number!(tt) == 2


tt = TrainTrack([[1, 2], [-1, -2]])
@test add_branch!(tt, BranchPosition(1, 0, LEFT), BranchPosition(-1, 0, RIGHT)) == 3
@test outgoing_branches(tt, 1) == [3, 1, 2]
@test outgoing_branches(tt, -1) == [-1, -2, -3]
@test branch_endpoint(tt, 3) == -1
@test branch_endpoint(tt, -3) == 1
@test !istwisted(tt, 3)

@test add_branch!(tt, 
    BranchPosition(1, 2, LEFT), 
    BranchPosition(1, 3, RIGHT), true) == 4
@test outgoing_branches(tt, 1) == [3, -4, 1, 4, 2]
@test istwisted(tt, 4)

@testset "Adding a switch on a branch" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    @test add_switch_on_branch!(tt, 1) == (2, 3)
    @test outgoing_branches(tt, 1) == [1, 2]
    @test outgoing_branches(tt, -1) == [-3, -2]
    @test outgoing_branches(tt, 2) == [3]
    @test outgoing_branches(tt, -2) == [-1]
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, -1) == 1
    @test branch_endpoint(tt, 3) == -1
    @test branch_endpoint(tt, -3) == 2

    tt = TrainTrack([[1, 2], [-1, -2]], [1])
    @test add_switch_on_branch!(tt, 1) == (2, 3)
    @test istwisted(tt, 1)
    @test !istwisted(tt, 3)
end

@testset "twisted" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]], [3, 5])
    @test istwisted(tt, 1) == false
    @test istwisted(tt, -1) == false
    @test istwisted(tt, 3) == true
    @test istwisted(tt, -3) == true

    twist_branch!(tt, 1)
    @test istwisted(tt, 1) == true
    twist_branch!(tt, -1)
    @test istwisted(tt, 1) == false

end



tt = TrainTrack([[1, 2], [-1, -2]])
@test (Donut.TrainTracks.Operations._set_numoutgoing_branches!(tt, 1, 3); numoutgoing_branches(tt, 1) == 3)



@testset "Inserting and deleting branches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])

    Donut.TrainTracks.Operations._insert_outgoing_branches!(tt, BranchPosition(1, 0), [3, -3])
    @test numoutgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [3, -3, 1, 2]

    Donut.TrainTracks.Operations._insert_outgoing_branches!(tt, BranchPosition(1, 3, RIGHT), [100, 101, 102, 103])
    @test numoutgoing_branches(tt, 1) == 8
    @test outgoing_branches(tt, 1) == [3, 103, 102, 101, 100, -3, 1, 2]

    Donut.TrainTracks.Operations._insert_outgoing_branches!(tt, BranchPosition(-1, 0), [200, 201])
    @test numoutgoing_branches(tt, -1) == 4
    @test outgoing_branches(tt, -1) == [200, 201, -1, -2]

    tt = TrainTrack([[1, 2], [-1, -2]])
    Donut.TrainTracks.Operations._splice_outgoing_branches!(tt, BranchRange(1, 1:2, RIGHT), [4, 5, 6, 7])
    @test numoutgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [7, 6, 5, 4]

    Donut.TrainTracks.Operations._splice_outgoing_branches!(tt, BranchRange(1, 2:3), [100, 101, 102])
    @test numoutgoing_branches(tt, 1) == 5
    @test outgoing_branches(tt, 1) == [7, 100, 101, 102, 4]

    Donut.TrainTracks.Operations._delete_outgoing_branches!(tt, BranchRange(1, 1:1))
    @test numoutgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [100, 101, 102, 4]

    Donut.TrainTracks.Operations._delete_outgoing_branches!(tt, BranchRange(1, 3:4, RIGHT))
    @test numoutgoing_branches(tt, 1) == 2
    @test outgoing_branches(tt, 1) == [102, 4]
end


@testset "Collapsing branches" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, 3) == 1  # switch 1 is removed
    @test outgoing_branches(tt, 2) == [1, 2]
    @test outgoing_branches(tt, -2) == [-1, -2]
    @test branch_endpoint(tt, -1) == 2
    @test branch_endpoint(tt, -2) == 2
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, 2) == -2

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, -3) == 2
    @test outgoing_branches(tt, 1) == [1, 2]
    @test outgoing_branches(tt, -1) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, 1) == 2
    @test outgoing_branches(tt, 1) == [3, 2]
    @test outgoing_branches(tt, -1) == [-3, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, 2) == 2
    @test outgoing_branches(tt, 1) == [1, 3]
    @test outgoing_branches(tt, -1) == [-1, -3]
    @test_throws ErrorException collapse_branch!(tt, 1)

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], [1, 3])
    @test collapse_branch!(tt, 3) == 1
    @test outgoing_branches(tt, 2) == [2, 1]
    @test outgoing_branches(tt, -2) == [-1, -2]
    @test istwisted(tt, 1) == false
    @test istwisted(tt, 2) == true

end

@testset "Pulling switches apart" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    @test pull_switch_apart!(
        tt, BranchRange(1, 1:2), BranchRange(-1, 1:2)) == (2, 3)
    @test outgoing_branches(tt, 1) == [3]
    @test outgoing_branches(tt, -1) == [-1, -2]
    @test outgoing_branches(tt, 2) == [1, 2]
    @test outgoing_branches(tt, -2) == [-3]

    tt = TrainTrack([[1, 2], [-1, -2]])
    @test pull_switch_apart!(
        tt, BranchRange(1, 1:1, RIGHT), BranchRange(-1, 1:1, RIGHT)) == (2, 3)
    @test outgoing_branches(tt, 1) == [1, 3]
    @test outgoing_branches(tt, -1) == [-2]
    @test outgoing_branches(tt, 2) == [2]
    @test outgoing_branches(tt, -2) == [-1, -3]

    tt = TrainTrack([[1, 2], [-1, -2]])
    @test_throws ErrorException pull_switch_apart!(
        tt, BranchRange(1, 2:2), BranchRange(-1, 1:0))
    @test_throws ErrorException pull_switch_apart!(
        tt, BranchRange(1, 2:1), BranchRange(-1, 1:1))
    @test_throws ErrorException pull_switch_apart!(
        tt, BranchRange(1, 1:1), BranchRange(1, 1:1))

end



@testset "Deleting two-valent switch" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-4], [4], [-1, -2]])
    br_kept, br_removed = delete_two_valent_switch!(tt, 2)
    @test br_kept == 4
    @test br_removed == 3
    @test outgoing_branches(tt, 1) == [1, 2]
    @test outgoing_branches(tt, -1) == [-4]
    @test outgoing_branches(tt, 3) == [4]
    @test outgoing_branches(tt, -3) == [-1, -2]

    @test_throws AssertionError delete_two_valent_switch!(tt, 1)
end





@testset "Peeling" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    peel!(tt, 1, LEFT)
    @test outgoing_branches(tt, 1) == [1, 2]
    @test outgoing_branches(tt, -1) == [-1, -2]
end


end
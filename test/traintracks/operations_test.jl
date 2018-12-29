module TrainTrackOperationsTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks.Operations
using Donut.TrainTracks.ElementaryOps
using Donut
using Donut.Constants: LEFT, RIGHT

@testset "Renaming branches" begin
    tt = TrainTrack([[1, 3], [-1, -3]])
    @test !isbranch(tt, 2)
    renamebranch!(tt, 3, 2)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test isbranch(tt, 2)
    @test !isbranch(tt, 3)
    @test branch_endpoint(tt, 2) == -1
    @test branch_endpoint(tt, -2) == 1

    tt = TrainTrack([[1, 3], [-1, -3]])
    renamebranch!(tt, 3, -2)
    @test collect(outgoing_branches(tt, 1)) == [1, -2]
    @test collect(outgoing_branches(tt, -1)) == [-1, 2]
    @test branch_endpoint(tt, 2) == 1
    @test branch_endpoint(tt, -2) == -1
end

@testset "Reversing branches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    reversebranch!(tt, 1)
    @test collect(outgoing_branches(tt, 1)) == [-1, 2]
    @test collect(outgoing_branches(tt, -1)) == [1, -2]
    @test branch_endpoint(tt, 1) == 1
    @test branch_endpoint(tt, -1) == -1
end

@testset "Renaming switches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    x = Donut.TrainTracks.Operations._find_new_switch_number!(tt)
    @test !isswitch(tt, 2)
    @test x == 2
    renameswitch!(tt, 1, 2)
    @test !isswitch(tt, 1)
    @test isswitch(tt, 2)
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, -1) == 2
    @test branch_endpoint(tt, 2) == -2
    @test branch_endpoint(tt, -2) == 2

    tt = TrainTrack([[1, 2], [-1, -2]])
    x = Donut.TrainTracks.Operations._find_new_switch_number!(tt)
    renameswitch!(tt, 1, -2)
    @test collect(outgoing_branches(tt, -2)) == [1, 2]
    @test collect(outgoing_branches(tt, 2)) == [-1, -2]
    @test branch_endpoint(tt, 1) == 2
    @test branch_endpoint(tt, -1) == -2
    @test branch_endpoint(tt, 2) == 2
    @test branch_endpoint(tt, -2) == -2
end

@testset "Reversing switches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    reverseswitch!(tt, 1)
    @test collect(outgoing_branches(tt, -1)) == [1, 2]
    @test collect(outgoing_branches(tt, 1)) == [-1, -2]
    @test branch_endpoint(tt, 1) == 1
    @test branch_endpoint(tt, -1) == -1
    @test branch_endpoint(tt, 2) == 1
    @test branch_endpoint(tt, -2) == -1 
end

tt = TrainTrack([[1, 2], [-1, -2]])
Donut.TrainTracks.Operations.delete_branch!(tt, 1)
@test collect(outgoing_branches(tt, 1)) == [2]
@test collect(outgoing_branches(tt, -1)) == [-2]
@test collect(branches(tt)) == [2]

tt = TrainTrack([[1, 2], [-1, -2]])
@test Donut.TrainTracks.Operations._find_new_switch_number!(tt) == 2

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
@test collapse_branch!(tt, 3) == 1  # switch 1 is removed
@test !isswitch(tt, 1)
@test collect(switches(tt)) == [2]
@test Donut.TrainTracks.Operations._find_new_switch_number!(tt) == 1

tt = TrainTrack([[1, 2], [-1, -2]])
@test Donut.TrainTracks.Operations._find_new_branch_number!(tt) == 3


# tt = TrainTrack([[1, 2], [-1, -2]])
# @test add_branch!(tt, BranchPosition(1, 0, LEFT), BranchPosition(-1, 0, RIGHT)) == 3
# @test collect(outgoing_branches(tt, 1)) == [3, 1, 2]
# @test collect(outgoing_branches(tt, -1)) == [-1, -2, -3]
# @test branch_endpoint(tt, 3) == -1
# @test branch_endpoint(tt, -3) == 1
# @test !istwisted(tt, 3)

# @test add_branch!(tt, 
#     BranchPosition(1, 2, LEFT), 
#     BranchPosition(1, 3, RIGHT), true) == 4
# @test outgoing_branches(tt, 1) == [3, -4, 1, 4, 2]
# @test istwisted(tt, 4)


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





@testset "Collapsing branches" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, 3) == 1  # switch 1 is removed
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test branch_endpoint(tt, -1) == 2
    @test branch_endpoint(tt, -2) == 2
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, 2) == -2

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, -3) == 2
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]


    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], [1, 3])
    @test collapse_branch!(tt, 3) == 1
    @test collect(outgoing_branches(tt, 2)) == [2, 1]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test istwisted(tt, 1) == false
    @test istwisted(tt, 2) == true

end

@testset "Pulling switches apart" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    @test pull_switch_apart!(tt, 1) == (2, 3)
    @test collect(outgoing_branches(tt, 1)) == [3]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-3]


end

@testset "Adding a switch on a branch" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    @test add_switch_on_branch!(tt, 1) == (2, 3)
    @test collect(outgoing_branches(tt, 1)) == [3, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test collect(outgoing_branches(tt, 2)) == [1]
    @test collect(outgoing_branches(tt, -2)) == [-3]
    @test branch_endpoint(tt, 3) == -2
    @test branch_endpoint(tt, -3) == 1
    @test branch_endpoint(tt, 1) == -1
    @test branch_endpoint(tt, -1) == 2

    tt = TrainTrack([[1, 2], [-1, -2]], [1])
    @test add_switch_on_branch!(tt, 1) == (2, 3)
    @test istwisted(tt, 1)
    @test !istwisted(tt, 3)
end


@testset "Deleting two-valent switch" begin
    tt = TrainTrack([[1, 2], [-4], [4], [-3], [3], [-1, -2]])
    delete_two_valent_switch!(tt, 2)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-4]
    @test collect(outgoing_branches(tt, 3)) == [4]
    @test collect(outgoing_branches(tt, -3)) == [-1, -2]

    @test_throws AssertionError delete_two_valent_switch!(tt, 1)
end





@testset "Peeling" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    peel!(tt, 1, LEFT)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test_throws ErrorException peel!(tt, -1, RIGHT)  # there is only one outgoing branch

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    peel!(tt, -2, RIGHT)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-3, -2]
    @test collect(outgoing_branches(tt, 2)) == [3]
    @test collect(outgoing_branches(tt, -2)) == [-1]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], [3])
    peel!(tt, 1, RIGHT)
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [2, 3]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]    
end


@testset "Folding" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    fold!(tt, 1, RIGHT)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    fold!(tt, -2, LEFT)
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    fold!(tt, 1, RIGHT)
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [3, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3, 4], [-4, -1, -2]], [3])
    fold!(tt, 3, RIGHT)
    @test collect(outgoing_branches(tt, 1)) == [4, 1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [3]
    @test collect(outgoing_branches(tt, -2)) == [-4, -1, -2]
    @test istwisted(tt, 3)
    @test istwisted(tt, 4)
end


@testset "Trivalent splittings" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    # @test_throws ErrorException split_trivalent!(tt, 1, LEFT)
    # @test_throws ErrorException split_trivalent!(tt, 2, LEFT)

    split_trivalent!(tt, 3, LEFT_SPLIT)
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3, -2]
    @test collect(outgoing_branches(tt, 2)) == [3, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    split_trivalent!(tt, 3, RIGHT_SPLIT)
    @test collect(outgoing_branches(tt, 1)) == [2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -3]
    @test collect(outgoing_branches(tt, 2)) == [1, 3]
    @test collect(outgoing_branches(tt, -2)) == [-2]
end


@testset "Trivalent foldings" begin
    tt = TrainTrack([[1, 3], [-2], [2], [-1, -3]])
    @test_throws ErrorException fold_trivalent!(tt, 2)

    fold_trivalent!(tt, 3)
    @test collect(outgoing_branches(tt, 1)) == [3]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-3]
end

end
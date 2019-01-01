module TrainTrackOperationsTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks: TrainTrack, _find_new_switch_number!, _find_new_branch_number!,
    twist_branch!
using Donut.Constants

@testset "Renaming branches" begin
    tt = TrainTrack([[1, 3], [-1, -3]])
    @test !isbranch(tt, 2)
    apply_tt_operation!(tt, RenameBranch(3, 2))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test isbranch(tt, 2)
    @test !isbranch(tt, 3)
    @test branch_endpoint(tt, 2) == -1
    @test branch_endpoint(tt, -2) == 1

    tt = TrainTrack([[1, 3], [-1, -3]])
    apply_tt_operation!(tt, RenameBranch(3, -2))
    @test collect(outgoing_branches(tt, 1)) == [1, -2]
    @test collect(outgoing_branches(tt, -1)) == [-1, 2]
    @test branch_endpoint(tt, 2) == 1
    @test branch_endpoint(tt, -2) == -1
end

@testset "Reversing branches" begin
    tt = DecoratedTrainTrack([[1, 2], [-1, -2]])
    apply_tt_operation!(tt, ReverseBranch(1))
    @test collect(outgoing_branches(tt, 1)) == [-1, 2]
    @test collect(outgoing_branches(tt, -1)) == [1, -2]
    @test branch_endpoint(tt, 1) == 1
    @test branch_endpoint(tt, -1) == -1
end

@testset "Renaming switches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    x = _find_new_switch_number!(tt)
    @test !isswitch(tt, 2)
    @test x == 2
    apply_tt_operation!(tt, RenameSwitch(1, 2))
    @test !isswitch(tt, 1)
    @test isswitch(tt, 2)
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, -1) == 2
    @test branch_endpoint(tt, 2) == -2
    @test branch_endpoint(tt, -2) == 2

    tt = TrainTrack([[1, 2], [-1, -2]])
    x = _find_new_switch_number!(tt)
    apply_tt_operation!(tt, RenameSwitch(1, -2))
    @test collect(outgoing_branches(tt, -2)) == [1, 2]
    @test collect(outgoing_branches(tt, 2)) == [-1, -2]
    @test branch_endpoint(tt, 1) == 2
    @test branch_endpoint(tt, -1) == -2
    @test branch_endpoint(tt, 2) == 2
    @test branch_endpoint(tt, -2) == -2
end

@testset "Reversing switches" begin
    tt = DecoratedTrainTrack([[1, 2], [-1, -2]])
    apply_tt_operation!(tt, ReverseSwitch(1))
    @test collect(outgoing_branches(tt, -1)) == [1, 2]
    @test collect(outgoing_branches(tt, 1)) == [-1, -2]
    @test branch_endpoint(tt, 1) == 1
    @test branch_endpoint(tt, -1) == -1
    @test branch_endpoint(tt, 2) == 1
    @test branch_endpoint(tt, -2) == -1 
end

tt = TrainTrack([[1, 2], [-1, -2]])
apply_tt_operation!(tt, DeleteBranch(1))
@test collect(outgoing_branches(tt, 1)) == [2]
@test collect(outgoing_branches(tt, -1)) == [-2]
@test collect(branches(tt)) == [2]

tt = TrainTrack([[1, 2], [-1, -2]])
@test _find_new_switch_number!(tt) == 2

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
@test apply_tt_operation!(tt, CollapseBranch(3)) == 1  # switch 1 is removed
@test !isswitch(tt, 1)
@test collect(switches(tt)) == [2]
@test _find_new_switch_number!(tt) == 1

tt = TrainTrack([[1, 2], [-1, -2]])
@test _find_new_branch_number!(tt) == 3


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
    @test apply_tt_operation!(tt, CollapseBranch(3)) == 1  # switch 1 is removed
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test branch_endpoint(tt, -1) == 2
    @test branch_endpoint(tt, -2) == 2
    @test branch_endpoint(tt, 1) == -2
    @test branch_endpoint(tt, 2) == -2

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test apply_tt_operation!(tt, CollapseBranch(-3)) == -2
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]


    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], [1, 3])
    @test apply_tt_operation!(tt, CollapseBranch(3)) == 1
    @test collect(outgoing_branches(tt, 2)) == [2, 1]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]
    @test istwisted(tt, 1) == false
    @test istwisted(tt, 2) == true

end

# @testset "Pulling switches apart" begin
#     tt = TrainTrack([[1, 2], [-1, -2]])
#     @test pull_switch_apart!(tt, 1) == (2, 3)
#     @test collect(outgoing_branches(tt, 1)) == [3]
#     @test collect(outgoing_branches(tt, -1)) == [-1, -2]
#     @test collect(outgoing_branches(tt, 2)) == [1, 2]
#     @test collect(outgoing_branches(tt, -2)) == [-3]


# end

@testset "Adding a switch on a branch" begin
    tt = DecoratedTrainTrack([[1, 2], [-1, -2]])
    @test apply_tt_operation!(tt, AddSwitchOnBranch(1)) == 2
    @test collect(outgoing_branches(tt, 1)) == [3, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test collect(outgoing_branches(tt, 2)) == [1]
    @test collect(outgoing_branches(tt, -2)) == [-3]
    @test branch_endpoint(tt, 3) == -2
    @test branch_endpoint(tt, -3) == 1
    @test branch_endpoint(tt, 1) == -1
    @test branch_endpoint(tt, -1) == 2

    tt = DecoratedTrainTrack([[1, 2], [-1, -2]], twisted_branches=[1])
    @test apply_tt_operation!(tt, AddSwitchOnBranch(1)) == 2
    @test istwisted(tt, 1)
    @test !istwisted(tt, 3)
end


@testset "Deleting two-valent switch" begin
    tt = DecoratedTrainTrack([[1, 2], [-4], [4], [-3], [3], [-1, -2]])
    apply_tt_operation!(tt, DeleteTwoValentSwitch(2))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-4]
    @test collect(outgoing_branches(tt, 3)) == [4]
    @test collect(outgoing_branches(tt, -3)) == [-1, -2]

    @test_throws AssertionError apply_tt_operation!(tt, DeleteTwoValentSwitch(1))
end





@testset "Peeling" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    apply_tt_operation!(tt, Peel(1, LEFT))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test_throws ErrorException apply_tt_operation!(tt, Peel(-1, RIGHT))  # there is only one outgoing branch

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    apply_tt_operation!(tt, Peel(-2, RIGHT))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-3, -2]
    @test collect(outgoing_branches(tt, 2)) == [3]
    @test collect(outgoing_branches(tt, -2)) == [-1]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], [3])
    apply_tt_operation!(tt, Peel(1, RIGHT))
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [2, 3]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]    
end


@testset "Folding" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    apply_tt_operation!(tt, Fold(1, RIGHT))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    apply_tt_operation!(tt, Fold(-2, LEFT))
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    apply_tt_operation!(tt, Fold(1, RIGHT))
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [3, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1, -2]

    tt = TrainTrack([[1, 2], [-3], [3, 4], [-4, -1, -2]], [3])
    apply_tt_operation!(tt, Fold(3, RIGHT))
    @test collect(outgoing_branches(tt, 1)) == [4, 1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-3]
    @test collect(outgoing_branches(tt, 2)) == [3]
    @test collect(outgoing_branches(tt, -2)) == [-4, -1, -2]
    @test istwisted(tt, 3)
    @test istwisted(tt, 4)
end


@testset "Trivalent splittings" begin
    tt = DecoratedTrainTrack([[1, 2], [-3], [3], [-1, -2]])
    # @test_throws ErrorException split_trivalent!(tt, 1, LEFT)
    # @test_throws ErrorException split_trivalent!(tt, 2, LEFT)

    apply_tt_operation!(tt, SplitTrivalent(3, LEFT_SPLIT))
    @test collect(outgoing_branches(tt, 1)) == [1]
    @test collect(outgoing_branches(tt, -1)) == [-3, -2]
    @test collect(outgoing_branches(tt, 2)) == [3, 2]
    @test collect(outgoing_branches(tt, -2)) == [-1]

    tt = DecoratedTrainTrack([[1, 2], [-3], [3], [-1, -2]])
    apply_tt_operation!(tt, SplitTrivalent(3, RIGHT_SPLIT))
    @test collect(outgoing_branches(tt, 1)) == [2]
    @test collect(outgoing_branches(tt, -1)) == [-1, -3]
    @test collect(outgoing_branches(tt, 2)) == [1, 3]
    @test collect(outgoing_branches(tt, -2)) == [-2]
end


@testset "Trivalent foldings" begin
    tt = DecoratedTrainTrack([[1, 3], [-2], [2], [-1, -3]])
    @test_throws ErrorException apply_tt_operation!(tt, FoldTrivalent(2))

    apply_tt_operation!(tt, FoldTrivalent(3))
    @test collect(outgoing_branches(tt, 1)) == [3]
    @test collect(outgoing_branches(tt, -1)) == [-1, -2]
    @test collect(outgoing_branches(tt, 2)) == [1, 2]
    @test collect(outgoing_branches(tt, -2)) == [-3]
end

end
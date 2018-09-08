using Test
include("../strudel/train_track.jl")

@test_throws ErrorException TrainTrack([[1, 2], [-2], [-1]])
@test_throws ErrorException TrainTrack([[1, 2], [2, -1]])
@test_throws ErrorException TrainTrack([[1, 2, -2, -1], Int[]])
@test_throws ErrorException TrainTrack([[1, 2], [-2]])
@test_throws ErrorException TrainTrack([[1, 2], [-2, -3]])
@test_throws ErrorException TrainTrack([[1, 2, -2], [-2, -1, 1]])

@test other_side(LEFT) == RIGHT
@test other_side(RIGHT) == LEFT
@test other_side(FORWARD) == BACKWARD
@test other_side(BACKWARD) == FORWARD
@test other_side(END) == START
@test other_side(START) == END

tt = TrainTrack([[1, 2], [-1, -2]])
@test num_outgoing_branches(tt, 1) == 2
@test num_outgoing_branches(tt, -1) == 2

@test is_switch_in_tt(tt, 1)
@test is_switch_in_tt(tt, -1)
@test !is_switch_in_tt(tt, 2)
@test !is_switch_in_tt(tt, -2)
@test !is_switch_in_tt(tt, 0)

@test is_branch_in_tt(tt, 1)
@test is_branch_in_tt(tt, -1)
@test is_branch_in_tt(tt, 2)
@test !is_branch_in_tt(tt, 3)
@test !is_branch_in_tt(tt, 0)


@test switch_valence(tt, 1) == 4
@test switch_valence(tt, -1) == 4

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


tt = TrainTrack([[1, 2], [-1, -2]])
delete_branch!(tt, 1)
@test tt.branches[1].endpoint == Int[0, 0]
@test tt.branches[1].is_twisted == false
@test !is_branch_in_tt(tt, 1)

tt = TrainTrack([[1, 2], [-1, -2]])
delete_switch!(tt, 1)
@test tt.switches[1].outgoing_branch_indices == [Int[], Int[]]
@test tt.switches[1].num_outgoing_branches == [0, 0]

tt = TrainTrack([[1, 2], [-1, -2]])
@test _create_switch!(tt) == 2

tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
@test collapse_branch!(tt, 3) == 1  # switch 1 is removed
@test !is_switch_in_tt(tt, 1)
@test _create_switch!(tt) == 1


@testset "twisted" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]], [3, 5])
    @test is_twisted(tt, 1) == false
    @test is_twisted(tt, -1) == false
    @test is_twisted(tt, 3) == true
    @test is_twisted(tt, -3) == true

    twist_branch!(tt, 1)
    @test is_twisted(tt, 1) == true
    twist_branch!(tt, -1)
    @test is_twisted(tt, 1) == false

end



tt = TrainTrack([[1, 2], [-1, -2]])
@test (_set_num_outgoing_branches!(tt, 1, 3); num_outgoing_branches(tt, 1) == 3)



@testset "Inserting and deleting branches" begin
    tt = TrainTrack([[1, 2], [-1, -2]])

    _insert_outgoing_branches!(tt, 1, 0, [3, -3])
    @test num_outgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [3, -3, 1, 2]

    _insert_outgoing_branches!(tt, 1, 3, [100, 101, 102, 103], RIGHT)
    @test num_outgoing_branches(tt, 1) == 8
    @test outgoing_branches(tt, 1) == [3, 103, 102, 101, 100, -3, 1, 2]

    _insert_outgoing_branches!(tt, -1, 0, [200, 201])
    @test num_outgoing_branches(tt, -1) == 4
    @test outgoing_branches(tt, -1) == [200, 201, -1, -2]

    tt = TrainTrack([[1, 2], [-1, -2]])
    _splice_outgoing_branches!(tt, 1, 1:2, [4, 5, 6, 7], RIGHT)
    @test num_outgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [7, 6, 5, 4]

    _splice_outgoing_branches!(tt, 1, 2:3, [100, 101, 102])
    @test num_outgoing_branches(tt, 1) == 5
    @test outgoing_branches(tt, 1) == [7, 100, 101, 102, 4]

    _delete_outgoing_branches!(tt, 1, 1:1)
    @test num_outgoing_branches(tt, 1) == 4
    @test outgoing_branches(tt, 1) == [100, 101, 102, 4]

    _delete_outgoing_branches!(tt, 1, 3:4, RIGHT)
    @test num_outgoing_branches(tt, 1) == 2
    @test outgoing_branches(tt, 1) == [102, 4]
end


@testset "Collapsing branches" begin
    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test collapse_branch!(tt, 3) == 1  # switch 1 is removed
    @test outgoing_branches(tt, 2) == [1, 2]
    @test outgoing_branches(tt, -2) == [-1, -2]

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
    @test is_twisted(tt, 1) == false
    @test is_twisted(tt, 2) == true

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

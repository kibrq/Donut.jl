
using Donut: trajectory_of_small_branch_or_cusp, add_carryingmap_as_small_tt!,
    are_trajectories_consistent, make_small_tt_trivalent!, TrainTrackNet,
    BRANCH, CUSP, new_branch_after_pullout

tt = TrainTrack([[1, 2], [-1, -2]], keep_trackof_cusps=true)
cm = CarryingMap(tt)

@test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == [(1, 1), (-1, 1)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, -1) == [(-1, 1), (1, 1)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == [(1, 3), (-1, 3)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, -2) == [(-1, 3), (1, 3)]
cusp1 = branch_to_cusp(cm.large_tt, 1, RIGHT)
# println("CUSP = ", CUSP)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp1) == [(1, 2)]
cusp2 = branch_to_cusp(cm.large_tt, -1, RIGHT)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp2) == [(-1, 2)]
@test are_trajectories_consistent(cm)

@testset "Pullout small branches" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]],
        measure=BigInt[1, 2, 6, 14, 100])
    ttnet = TrainTrackNet([tt])
    tt_index = 1
    _, cm = add_carryingmap_as_small_tt!(ttnet, tt_index)
    @test are_trajectories_consistent(cm, false)
    new_sw = apply_tt_operation!(ttnet, tt_index, PulloutBranches(1, 2, LEFT))
    new_br = new_branch_after_pullout(cm.small_tt.tt, new_sw)
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, new_br) == []
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == [(1, 1), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == [(1, 3), (-1, 7)]
    cusp = branch_to_cusp(cm.small_tt, 1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == [(1, 2)]
    @test branchmeasure(cm.small_tt, new_br) == 3
    @test are_trajectories_consistent(cm, false)
end


@testset "Making the small switch trivalent" begin
    tt = TrainTrack([[1, 2], [-1, -2]], measure=BigInt[3, 8])
    ttnet = TrainTrackNet([tt])
    _, cm = add_carryingmap_as_small_tt!(ttnet, 1)    
    @test are_trajectories_consistent(cm, false)
    make_small_tt_trivalent!(ttnet, 1)
    # println()
    @test are_trajectories_consistent(cm, false)

    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]],
        measure=BigInt[1, 0, 6, 14, 100])
    ttnet = TrainTrackNet([tt])
    _, cm = add_carryingmap_as_small_tt!(ttnet, 1) 
    @test are_trajectories_consistent(cm, false)
    make_small_tt_trivalent!(ttnet, 1)
    @test are_trajectories_consistent(cm, false)

end


@testset "Pullout large branches" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]])
    ttnet = TrainTrackNet([tt])
    large_index, cm = add_carryingmap_as_small_tt!(ttnet, 1)    
    new_sw = apply_tt_operation!(ttnet, large_index, PulloutBranches(1, 2, LEFT))
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 1), (-new_sw, 3), (new_sw, 1), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == 
        [(1, 3), (-new_sw, 1), (new_sw, 3), (-1, 7)]
    cusp = branch_to_cusp(cm.small_tt, 1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 2), (-new_sw, 2), (new_sw, 2)]
    @test are_trajectories_consistent(cm, false)
end


@testset "Peeling the small train track" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-1, -2, -3, -4, -5]], 
        measure=BigInt[1, 2, 6, 14, 100])
    ttnet = TrainTrackNet([tt])
    tt_index = 1
    _, cm = add_carryingmap_as_small_tt!(ttnet, tt_index)
    cusp = branch_to_cusp(cm.small_tt, 1, RIGHT)
    apply_tt_operation!(ttnet, tt_index, Peel(1, LEFT))
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 9), (-1, 11), (1, 1), (-1, 1)]
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 10), (-1, 10), (1, 2)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == 
        [(1, 3), (-1, 3)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 5) ==
        [(1, 11), (-1, 9)]

    @test are_trajectories_consistent(cm, false)

    apply_tt_operation!(ttnet, tt_index, Peel(-1, LEFT))
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 9), (-1, 13), (1, 1), (-1, 1), (1, 13), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 10), (-1, 12), (1, 2)]
    cusp2 = branch_to_cusp(cm.small_tt, -1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp2) == 
        [(-1, 10), (1, 12), (-1, 2)]  
        
    @test are_trajectories_consistent(cm, false)
end

@testset "Folding the large train track" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-1, -2, -3, -4, -5]])
    ttnet = TrainTrackNet([tt])
    tt_index = 1
    large_index, cm = add_carryingmap_as_small_tt!(ttnet, tt_index)
    cusp = branch_to_cusp(cm.small_tt, 1, RIGHT)
    apply_tt_operation!(ttnet, large_index, Fold(1, RIGHT))
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 1), (-1, 3)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == 
        [(1, 3), (-1, 1), (1, 11), (-1, 5)]
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 2), (-1, 2), (1, 10)]

    @test are_trajectories_consistent(cm, false)
end


module CarryingTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Cusps
using Donut.TrainTracks.Carrying
using Donut.TrainTracks.Carrying: are_trajectories_consistent
using Donut.Constants: LEFT, RIGHT

tt = TrainTrack([[1, 2], [-1, -2]])
cm = CarryingMap(tt)

@test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == [(1, 1), (-1, 1)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, -1) == [(-1, 1), (1, 1)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == [(1, 3), (-1, 3)]
@test trajectory_of_small_branch_or_cusp(cm, BRANCH, -2) == [(-1, 3), (1, 3)]
cusp1 = branch_to_cusp(cm.large_cusphandler, 1, RIGHT)
# println("CUSP = ", CUSP)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp1) == [(1, 2)]
cusp2 = branch_to_cusp(cm.large_cusphandler, -1, RIGHT)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp2) == [(-1, 2)]
@test are_trajectories_consistent(cm)

@testset "Pullout small branches" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]])
    cm = CarryingMap(tt)
    measure = Measure{BigInt}(tt, BigInt[1, 2, 6, 14, 100])
    @test are_trajectories_consistent(cm, false)
    iter = BranchIterator(cm.small_tt, 1, 2, LEFT)
    new_sw, new_br = pullout_branches_small!(cm, iter, measure)
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, new_br) == []
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == [(1, 1), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == [(1, 3), (-1, 7)]
    cusp = branch_to_cusp(cm.small_cusphandler, 1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == [(1, 2)]
    @test branchmeasure(measure, new_br) == 3
    @test are_trajectories_consistent(cm, false)
end


@testset "Making the small switch trivalent" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    cm = CarryingMap(tt)
    measure = Measure{BigInt}(tt, BigInt[3, 8])
    @test are_trajectories_consistent(cm, false)
    make_small_tt_trivalent!(cm, measure)
    # println()
    @test are_trajectories_consistent(cm, false)

    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]])
    cm = CarryingMap(tt)
    measure = Measure{BigInt}(tt, BigInt[1, 0, 6, 14, 100])
    @test are_trajectories_consistent(cm, false)
    make_small_tt_trivalent!(cm, measure)
    @test are_trajectories_consistent(cm, false)

end


@testset "Pullout large branches" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-5, -4, -3, -2, -1]])
    cm = CarryingMap(tt)
    iter = BranchIterator(cm.large_tt, 1, 2, LEFT)
    new_sw, new_br = pullout_branches_large!(cm, iter)
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 1), (-new_sw, 3), (new_sw, 1), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == 
        [(1, 3), (-new_sw, 1), (new_sw, 3), (-1, 7)]
    cusp = branch_to_cusp(cm.small_cusphandler, 1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 2), (-new_sw, 2), (new_sw, 2)]
    @test are_trajectories_consistent(cm, false)
end


@testset "Peeling the small train track" begin
    tt = TrainTrack([[1, 2, 3, 4, 5], [-1, -2, -3, -4, -5]])
    measure = Measure{BigInt}(tt, BigInt[1, 2, 6, 14, 100])
    cm = CarryingMap(tt)
    cusp = branch_to_cusp(cm.small_cusphandler, 1, RIGHT)
    peel_small!(cm, 1, LEFT, measure)
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 9), (-1, 11), (1, 1), (-1, 1)]
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 10), (-1, 10), (1, 2)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 2) == 
        [(1, 3), (-1, 3)]
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 5) ==
        [(1, 11), (-1, 9)]

    @test are_trajectories_consistent(cm, false)

    peel_small!(cm, -1, LEFT, measure)
    @test trajectory_of_small_branch_or_cusp(cm, BRANCH, 1) == 
        [(1, 9), (-1, 13), (1, 1), (-1, 1), (1, 13), (-1, 9)]
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp) == 
        [(1, 10), (-1, 12), (1, 2)]
    cusp2 = branch_to_cusp(cm.small_cusphandler, -1, RIGHT)
    @test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp2) == 
        [(-1, 10), (1, 12), (-1, 2)]  
        
    @test are_trajectories_consistent(cm, false)
end


end
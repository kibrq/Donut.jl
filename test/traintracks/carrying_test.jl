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
cusp1 = branch_to_cusp(cm.large_tt, cm.large_cusphandler, 1, RIGHT)
# println("CUSP = ", CUSP)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp1) == [(1, 2)]
cusp2 = branch_to_cusp(cm.large_tt, cm.large_cusphandler, -1, RIGHT)
@test trajectory_of_small_branch_or_cusp(cm, CUSP, cusp2) == [(-1, 2)]
@test are_trajectories_consistent(cm)

@testset "Making the small switch trivalent" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    cm = CarryingMap(tt)
    measure = Measure{BigInt}(tt, BigInt[3, 8])
    make_small_tt_trivalent!(cm, measure)
    # println()
    @test are_trajectories_consistent(cm)
    
end

end
module CarryingTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks.Cusps
using Donut.TrainTracks.Carrying
using Donut.TrainTracks.Carrying: trajectory_of_small_branch_or_path
using Donut.Constants: LEFT, RIGHT

tt = TrainTrack([[1, 2], [-1, -2]])
cm = CarryingMap(tt, CuspHandler(tt))

@test trajectory_of_small_branch_or_path(cm, BRANCH, 1) == [(1, 1), (-1, 1)]
@test trajectory_of_small_branch_or_path(cm, BRANCH, -1) == [(-1, 1), (1, 1)]
@test trajectory_of_small_branch_or_path(cm, BRANCH, 2) == [(1, 3), (-1, 3)]
@test trajectory_of_small_branch_or_path(cm, BRANCH, -2) == [(-1, 3), (1, 3)]
cusp1 = branch_to_cusp(cm.large_tt, cm.large_cusphandler, 1, RIGHT)
# println("CUSP = ", CUSP)
@test trajectory_of_small_branch_or_path(cm, CUSP, cusp1) == [(1, 2), cusp1]
cusp2 = branch_to_cusp(cm.large_tt, cm.large_cusphandler, -1, RIGHT)
@test trajectory_of_small_branch_or_path(cm, CUSP, cusp2) == [(-1, 2), cusp2]


end
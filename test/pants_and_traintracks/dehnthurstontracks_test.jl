module DehnThurstonTracksTest

using Test
using Donut.Pants
using Donut.PantsAndTrainTracks
using Donut.Constants: LEFT, RIGHT
using Donut.TrainTracks

pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
tt = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])

@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 8
@test switchvalence(tt, 2) == 5
@test switchvalence(tt, 3) == 5
@test numoutgoing_branches(tt, 1) == 3
@test numoutgoing_branches(tt, 2) == 2
@test numoutgoing_branches(tt, 3) == 3

pd = PantsDecomposition([[1, 2, 3], [-2, -3, 4]])
# dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
# in the first pant, only 2 and 3 are inner pants curves
@test_throws ErrorException dehnthurstontrack(pd, [0, 1], [LEFT, LEFT])
@test_throws ErrorException dehnthurstontrack(pd, [1, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [2, 1], [LEFT, LEFT])
dehnthurstontrack(pd, [3, 1], [LEFT, LEFT])

pd = PantsDecomposition([[1, 2, 3], [-2, 4, 5], [-3, 6, 6]])
tt = dehnthurstontrack(pd, [3, 1, 0], [RIGHT, LEFT, LEFT])
@test switches(tt) == [1, 2, 3]
@test length(branches(tt)) == 9
@test switchvalence(tt, 1) == 5
@test switchvalence(tt, 2) == 7
@test switchvalence(tt, 3) == 6
@test numoutgoing_branches(tt, 1) == 2
@test numoutgoing_branches(tt, 2) == 3
@test numoutgoing_branches(tt, 3) == 3
end
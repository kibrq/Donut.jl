module CarryingTest

using Test
using Donut.TrainTracks
using Donut.Carrying


tt = TrainTrack([[1, 2], [-1, -2]])
cm = CarryingMap(tt)

@test cusp_nextto_branch(cm, 1, LEFT) == 0
@test cusp_nextto_branch(cm, 1, RIGHT) == 1
@test cusp_nextto_branch(cm, 2, LEFT) == 1
@test cusp_nextto_branch(cm, 2, RIGHT) == 0
@test cusp_nextto_branch(cm, -1, LEFT) == 0
@test cusp_nextto_branch(cm, -1, RIGHT) == 2
@test cusp_nextto_branch(cm, -2, LEFT) == 2
@test cusp_nextto_branch(cm, -2, RIGHT) == 0

@test interval_next_to_small_switch(cm, 1, LEFT) == 1
@test interval_next_to_small_switch(cm, 1, RIGHT) == 2
@test interval_next_to_small_switch(cm, -1, LEFT) == -2
@test interval_next_to_small_switch(cm, -2, RIGHT) == -1


end



tt = TrainTrack([[1, 2], [-1, -2]])
measure = TrainTrackMeasure{Int}(tt, [3, 8])
@test branchmeasure(measure, 1) == 3
@test branchmeasure(measure, -1) == 3
@test branchmeasure(measure, 2) == 8
@test branchmeasure(measure, -2) == 8
@test typeof(branchmeasure(measure, -2)) == Int

measure = TrainTrackMeasure{BigInt}(tt, BigInt[3, 8])
@test typeof(branchmeasure(measure, -2)) == BigInt

measure = Donut.zeromeasure(tt, Int)
@test branchmeasure(measure, 1) == 0
@test branchmeasure(measure, -2) == 0


module MeasureTest

using Test
using Donut.TrainTracks: TrainTrack
using Donut.TrainTracks.Measures: Measure, branchmeasure, zeromeasure

tt = TrainTrack([[1, 2], [-1, -2]])
measure = Measure{Int}(tt, [3, 8])
@test branchmeasure(measure, 1) == 3
@test branchmeasure(measure, -1) == 3
@test branchmeasure(measure, 2) == 8
@test branchmeasure(measure, -2) == 8
@test typeof(branchmeasure(measure, -2)) == Int

measure = Measure{BigInt}(tt, BigInt[3, 8])
@test typeof(branchmeasure(measure, -2)) == BigInt

measure = zeromeasure(tt, Int)
@test branchmeasure(measure, 1) == 0
@test branchmeasure(measure, -2) == 0


end
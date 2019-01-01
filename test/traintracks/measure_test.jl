
module MeasureTest

using Test
using Donut.TrainTracks
using Donut.TrainTracks: TrainTrack, zeromeasure
import Donut


@testset "Measures" begin
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

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test_throws ErrorException Measure{Int}(tt, [3, 1, 8])
    @test_throws ErrorException Measure{Int}(tt, [3, 8])
    @test_throws ErrorException Measure{Int}(tt, [-1, -1, -2])

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    measure = Measure{Int}(tt, [3, 5, 8])
    Donut.TrainTracks._setmeasure!(measure, 3, 100)
    @test branchmeasure(measure, 3) == 100
end

end
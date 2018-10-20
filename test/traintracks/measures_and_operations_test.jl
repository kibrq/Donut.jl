module MeasuresAndOperationsTest

using Test
using Donut.TrainTracks.MeasuresAndOperations
using Donut.TrainTracks.Measures
using Donut.TrainTracks
using Donut.Constants: LEFT, RIGHT

@testset "Peeling" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    measure = Measure{Int}(tt, [3, 8])
    peel!(tt, 1, LEFT, measure)
    @test branchmeasure(measure, 1) == 3
    @test branchmeasure(measure, 2) == 5

    tt = TrainTrack([[1, 2], [-1, -2]])
    measure = Measure{Int}(tt, [3, 8])
    peel!(tt, 1, RIGHT, measure)
    @test branchmeasure(measure, 1) == -5
    @test branchmeasure(measure, 2) == 8

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]])
    measure = Measure{Int}(tt, [3, 5, 8])
    peel!(tt, -2, RIGHT, measure)
    @test branchmeasure(measure, 1) == 3
    @test branchmeasure(measure, 2) == 5
    @test branchmeasure(measure, 3) == 3
    @test outgoing_branches(tt, 1) == [1, 2]
    @test outgoing_branches(tt, -1) == [-3, -2]
    @test outgoing_branches(tt, 2) == [3]
    @test outgoing_branches(tt, -2) == [-1]
end

@testset "Folding" begin
    tt = TrainTrack([[1, 2], [-1, -2]])
    measure = Measure{Int}(tt, [11, 2])
    fold!(tt, 1, LEFT, measure)
    @test branchmeasure(measure, 1) == 11
    @test branchmeasure(measure, 2) == 13

    tt = TrainTrack([[1, 2], [-1, -2]])
    measure = Measure{Float64}(tt, [11.0, 2.0])
    fold!(tt, -1, RIGHT, measure)
    @test branchmeasure(measure, 1) == 13.0
    @test branchmeasure(measure, 2) == 2.0
end


end
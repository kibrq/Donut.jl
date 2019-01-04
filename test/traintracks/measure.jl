
using Donut: Measure, zeromeasure, _setmeasure!

@testset "Measures" begin
    tt = PlainTrainTrack([[1, 2], [-1, -2]])
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

    tt = PlainTrainTrack([[1, 2], [-3], [3], [-1, -2]])
    @test_throws ErrorException Measure{Int}(tt, [3, 1, 8])
    @test_throws ErrorException Measure{Int}(tt, [3, 8])
    @test_throws ErrorException Measure{Int}(tt, [-1, -1, -2])

    tt = PlainTrainTrack([[1, 2], [-3], [3], [-1, -2]])
    measure = Measure{Int}(tt, [3, 5, 8])
    _setmeasure!(measure, 3, 100)
    @test branchmeasure(measure, 3) == 100
end



@testset "Peeling" begin
    tt = TrainTrack([[1, 2], [-1, -2]], measure=[3, 8])
    apply_tt_operation!(tt, Peel(1, LEFT))
    @test branchmeasure(tt, 1) == 3
    @test branchmeasure(tt, 2) == 5

    tt = TrainTrack([[1, 2], [-1, -2]], measure=[3, 8])
    apply_tt_operation!(tt, Peel(1, RIGHT))
    @test branchmeasure(tt, 1) == -5
    @test branchmeasure(tt, 2) == 8

    tt = TrainTrack([[1, 2], [-3], [3], [-1, -2]], measure=[3, 5, 8])
    apply_tt_operation!(tt, Peel(-2, RIGHT))
    @test branchmeasure(tt, 1) == 3
    @test branchmeasure(tt, 2) == 5
    @test branchmeasure(tt, 3) == 3
    @test collect(outgoing_branches(tt, 1)) == [1, 2]
    @test collect(outgoing_branches(tt, -1)) == [-3, -2]
    @test collect(outgoing_branches(tt, 2)) == [3]
    @test collect(outgoing_branches(tt, -2)) == [-1]
end

@testset "Folding" begin
    tt = TrainTrack([[1, 2], [-1, -2]], measure=[11, 2])
    apply_tt_operation!(tt, Fold(2, LEFT))
    @test branchmeasure(tt, 1) == 11
    @test branchmeasure(tt, 2) == 13

    tt = TrainTrack([[1, 2], [-1, -2]], measure=[11.0, 2.0])
    apply_tt_operation!(tt, Fold(-1, RIGHT))
    @test branchmeasure(tt, 1) == 13.0
    @test branchmeasure(tt, 2) == 2.0
end


module MeasuresAndOperationsTest

using Test
using Donut.TrainTracks
using Donut.Constants: LEFT, RIGHT

@testset "Peeling" begin
    tt = DecoratedTrainTrack([[1, 2], [-1, -2]], measure=[3, 8])
    apply_tt_operation!(tt, Peel(1, LEFT))
    @test branchmeasure(tt, 1) == 3
    @test branchmeasure(tt, 2) == 5

    tt = DecoratedTrainTrack([[1, 2], [-1, -2]], measure=[3, 8])
    apply_tt_operation!(tt, Peel(1, RIGHT))
    @test branchmeasure(tt, 1) == -5
    @test branchmeasure(tt, 2) == 8

    tt = DecoratedTrainTrack([[1, 2], [-3], [3], [-1, -2]], measure=[3, 5, 8])
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
    tt = DecoratedTrainTrack([[1, 2], [-1, -2]], measure=[11, 2])
    apply_tt_operation!(tt, Fold(2, LEFT))
    @test branchmeasure(tt, 1) == 11
    @test branchmeasure(tt, 2) == 13

    tt = DecoratedTrainTrack([[1, 2], [-1, -2]], measure=[11.0, 2.0])
    apply_tt_operation!(tt, Fold(-1, RIGHT))
    @test branchmeasure(tt, 1) == 13.0
    @test branchmeasure(tt, 2) == 2.0
end


end
module IsotopyAfterElementaryMovesTest

using Test

using Donut.PantsAndTrainTracks.DehnThurstonTracks
using Donut.PantsAndTrainTracks.IsotopyAfterElementaryMoves
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.Constants: LEFT, RIGHT
using Donut.Pants

@testset "Dehn twists" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, Twist(-3, LEFT), encodings)
    @test gluinglist(pd) == [(1, 2, 3), (-3, -2, -1)]
    @test sum(length(item[2]) for item in encoding_changes) == 4   

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, Twist(1, RIGHT), encodings)
    @test gluinglist(pd) == [(1, 2, 3), (-3, -2, -1)]
    @test sum(length(item[2]) for item in encoding_changes) == 7
end


@testset "Half twists" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, HalfTwist(-1, LEFT), encodings)
    @test gluinglist(pd) == [(1, 2, 3), (-2, -3, -1)]
    @test sum(length(item[2]) for item in encoding_changes) == 6

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, HalfTwist(1, LEFT), encodings)
    @test gluinglist(pd) == [(1, 3, 2), (-3, -2, -1)]
    @test sum(length(item[2]) for item in encoding_changes) == 6 
end


@testset "First move" begin
    pd = PantsDecomposition([(1, -1, 2), (-2, 3, -3)])
    tt, encodings, _ = dehnthurstontrack(pd, [3, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, FirstMove(1), encodings)
    @test gluinglist(pd) == [(1, -1, 2), (-2, 3, -3)]
    @test sum(length(item[2]) for item in encoding_changes) == 7

    pd = PantsDecomposition([(1, -1, 2), (-2, 3, -3)])
    tt, encodings, _ = dehnthurstontrack(pd, [3, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, FirstMove(3), encodings)
    @test gluinglist(pd) == [(1, -1, 2), (-2, 3, -3)]
    @test sum(length(item[2]) for item in encoding_changes) == 5
end

@testset "Second move" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, SecondMove(1), encodings)
    @test gluinglist(pd) == [(1, 3, -3), (-1, -2, 2)]
    @test sum(length(item[2]) for item in encoding_changes) == 11 

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, encodings, _ = dehnthurstontrack(pd, [1, 0], [LEFT, RIGHT, LEFT])
    encoding_changes = update_encodings_aftermove!(tt, pd, SecondMove(2), encodings)
    @test gluinglist(pd) == [(2, 1, -1), (-2, -3, 3)]
    @test sum(length(item[2]) for item in encoding_changes) == 15
end

end

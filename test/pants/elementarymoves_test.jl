module ElementaryMovesTest

using Test
using Donut.Pants
using Donut.Pants: gluinglist
using Donut.Pants.ElementaryMoves
using Donut.Constants: LEFT, RIGHT

@testset "Move 2" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_move!(pd, SecondMove(2))
    @test gluinglist(pd) == [(2, 1, -1), (-2, -3, 3)]
    @test separator_to_region(pd, 2, LEFT) == 1
    @test separator_to_region(pd, 2, RIGHT) == 2
    @test separator_to_region(pd, 1, LEFT) == 1
    @test separator_to_region(pd, 1, RIGHT) == 1
    @test separator_to_region(pd, 3, LEFT) == 2
    @test separator_to_region(pd, 3, RIGHT) == 2
    @test separator_to_bdyindex(pd, 1, LEFT) == BdyIndex(2)
    @test separator_to_bdyindex(pd, 1, RIGHT) == BdyIndex(3)
    @test separator_to_bdyindex(pd, 2, LEFT) == BdyIndex(1)
    @test separator_to_bdyindex(pd, 2, RIGHT) == BdyIndex(1)
    @test separator_to_bdyindex(pd, 3, LEFT) == BdyIndex(3)
    @test separator_to_bdyindex(pd, 3, RIGHT) == BdyIndex(2)
    apply_move!(pd, SecondMove(2))
    @test gluinglist(pd) == [(2, -1, -3), (-2, 3, 1)]
    apply_move!(pd, SecondMove(2))
    @test gluinglist(pd) == [(2, -3, 3), (-2, 1, -1)]
    apply_move!(pd, SecondMove(2))
    @test gluinglist(pd) == [(2, 3, 1), (-2, -1, -3)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_move!(pd, SecondMove(-2))
    @test gluinglist(pd) == [(2, 1, -1), (-2, -3, 3)]
    apply_move!(pd, SecondMove(-2))
    @test gluinglist(pd) == [(2, -1, -3), (-2, 3, 1)]
    apply_move!(pd, SecondMove(-2))
    @test gluinglist(pd) == [(2, -3, 3), (-2, 1, -1)]
    apply_move!(pd, SecondMove(-2))
    @test gluinglist(pd) == [(2, 3, 1), (-2, -1, -3)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_move!(pd, SecondMove(1))
    @test gluinglist(pd) == [(1, 3, -3), (-1, -2, 2)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_move!(pd, SecondMove(3))
    @test gluinglist(pd) == [(3, 2, -2), (-3, -1, 1)]
end



@testset "Halftwist" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_move!(pd, HalfTwist(2, LEFT))
    @test gluinglist(pd) == [(3, 2, 1), (-3, -2, -1)]
    @test separator_to_region(pd, 1, LEFT) == 1
    @test separator_to_region(pd, 2, LEFT) == 1
    @test separator_to_region(pd, 2, LEFT) == 1
    @test separator_to_bdyindex(pd, 1, LEFT) == BdyIndex(3)
    @test separator_to_bdyindex(pd, 2, LEFT) == BdyIndex(2)
    @test separator_to_bdyindex(pd, 3, LEFT) == BdyIndex(1)
end


end
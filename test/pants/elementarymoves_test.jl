module ElementaryMovesTest

using Test
using Donut.Pants
using Donut.Pants: gluinglist
using Donut.Pants.ElementaryMoves
using Donut.Constants: LEFT, RIGHT

@testset "Move 2" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_secondmove!(pd, 2)
    @test gluinglist(pd) == [(2, 1, -1), (-2, -3, 3)]
    @test pant_nextto_pantscurve(pd, 2, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 2, RIGHT) == 2
    @test pant_nextto_pantscurve(pd, 1, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 1, RIGHT) == 1
    @test pant_nextto_pantscurve(pd, 3, LEFT) == 2
    @test pant_nextto_pantscurve(pd, 3, RIGHT) == 2
    @test bdyindex_nextto_pantscurve(pd, 1, LEFT) == BdyIndex(2)
    @test bdyindex_nextto_pantscurve(pd, 1, RIGHT) == BdyIndex(3)
    @test bdyindex_nextto_pantscurve(pd, 2, LEFT) == BdyIndex(1)
    @test bdyindex_nextto_pantscurve(pd, 2, RIGHT) == BdyIndex(1)
    @test bdyindex_nextto_pantscurve(pd, 3, LEFT) == BdyIndex(3)
    @test bdyindex_nextto_pantscurve(pd, 3, RIGHT) == BdyIndex(2)
    apply_secondmove!(pd, 2)
    @test gluinglist(pd) == [(2, -1, -3), (-2, 3, 1)]
    apply_secondmove!(pd, 2)
    @test gluinglist(pd) == [(2, -3, 3), (-2, 1, -1)]
    apply_secondmove!(pd, 2)
    @test gluinglist(pd) == [(2, 3, 1), (-2, -1, -3)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_secondmove!(pd, -2)
    @test gluinglist(pd) == [(2, 1, -1), (-2, -3, 3)]
    apply_secondmove!(pd, -2)
    @test gluinglist(pd) == [(2, -1, -3), (-2, 3, 1)]
    apply_secondmove!(pd, -2)
    @test gluinglist(pd) == [(2, -3, 3), (-2, 1, -1)]
    apply_secondmove!(pd, -2)
    @test gluinglist(pd) == [(2, 3, 1), (-2, -1, -3)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_secondmove!(pd, 1)
    @test gluinglist(pd) == [(1, 3, -3), (-1, -2, 2)]

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_secondmove!(pd, 3)
    @test gluinglist(pd) == [(3, 2, -2), (-3, -1, 1)]
end



@testset "Halftwist" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    apply_halftwist!(pd, 1, BdyIndex(2))
    @test gluinglist(pd) == [(3, 2, 1), (-3, -2, -1)]
    @test pant_nextto_pantscurve(pd, 1, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 2, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 2, LEFT) == 1
    @test bdyindex_nextto_pantscurve(pd, 1, LEFT) == BdyIndex(3)
    @test bdyindex_nextto_pantscurve(pd, 2, LEFT) == BdyIndex(2)
    @test bdyindex_nextto_pantscurve(pd, 3, LEFT) == BdyIndex(1)
end


end
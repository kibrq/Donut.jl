module PantsTest

using Test
using Donut.Pants
using Donut.Constants: LEFT, RIGHT

# PantsDecomposition([(1, 2, 3), (-2, -2, -1)])
@test_throws ErrorException PantsDecomposition([(1, 2, 3), (-2, -2, -1)])
@test_throws ErrorException PantsDecomposition([(1, 2, 0), (3, -2, -1)])

@testset "Simple genus 2 pants decomposition" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test pants(pd) == [1, 2]
    @test numpants(pd) == 2
    @test numpunctures(pd) == 0
    @test numboundarycurves(pd) == 0
    @test eulerchar(pd) == -2
    @test collect(boundarycurveindices(pd)) == Int[]
    @test collect(innercurveindices(pd)) == [1, 2, 3]
    @test collect(curveindices(pd)) == [1, 2, 3]
    @test !isboundary_pantscurve(pd, 1)
    @test !isboundary_pantscurve(pd, -1)
    @test_throws BoundsError isboundary_pantscurve(pd, 4)
    @test isinner_pantscurve(pd, 1)
    @test isinner_pantscurve(pd, -1)
    @test_throws BoundsError isinner_pantscurve(pd, 4)
    @test pant_nextto_pantscurve(pd, 1, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 1, RIGHT) == 2
    @test pant_nextto_pantscurve(pd, -1, LEFT) == 2
    @test pant_nextto_pantscurve(pd, -1, RIGHT) == 1
    @test pant_nextto_pantscurve(pd, 3, LEFT) == 1
    @test pant_nextto_pantscurve(pd, 3, RIGHT) == 2
    @test pant_nextto_pantscurve(pd, -3, LEFT) == 2
    @test pant_nextto_pantscurve(pd, -3, RIGHT) == 1
end

@testset "Pants decomposition with one-sided curves, boundary, and orientation-reversing gluings" begin
    pd = PantsDecomposition([(4, 6, 3), (-3, 2, 5), (-2, 1, -1)])
    @test collect(boundarycurveindices(pd)) == [4, 5, 6]
    @test collect(curveindices(pd)) == [1, 2, 3, 4, 5, 6]
    @test collect(innercurveindices(pd)) == [1, 2, 3]
    @test isboundary_pantscurve(pd, 4)
    @test isboundary_pantscurve(pd, -5)
    @test isinner_pantscurve(pd, -1)
    @test isinner_pantscurve(pd ,2)
end

end
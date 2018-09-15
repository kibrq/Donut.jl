module PantsTest

using Test
using Donut.Pants
using Donut.Constants: LEFT, RIGHT

@test_throws ErrorException PantsDecomposition([[1, 2, 3], [-2, -2, -1]])
@test_throws ErrorException PantsDecomposition([[1, 2, 3, -3], [-2, -1]])
@test_throws ErrorException PantsDecomposition([[1, 2, 0], [3, -2, -1]])

@testset "Simple genus 2 pants decomposition" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test pants(pd) == [1, 2]
    @test numpants(pd) == 2
    @test numpunctures(pd) == 0
    @test numboundarycurves(pd) == 0
    @test eulerchar(pd) == -2
    @test ispantscurve(pd, -2)
    @test ispantscurve(pd, 3)
    @test !ispantscurve(pd, 5)
    @test boundarycurveindices(pd) == Int[]
    @test innercurveindices(pd) == [1, 2, 3]
    @test curveindices(pd) == [1, 2, 3]
    @test !isboundary_pantscurve(pd, 1)
    @test !isboundary_pantscurve(pd, -1)
    @test !isboundary_pantscurve(pd, 4)
    @test isinner_pantscurve(pd, 1)
    @test isinner_pantscurve(pd, -1)
    @test !isinner_pantscurve(pd, 4)
    @test istwosided_pantscurve(pd, 1)
    @test istwosided_pantscurve(pd, -1)
    @test !isonesided_pantscurve(pd, 3)
    @test !isonesided_pantscurve(pd, -3)
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
    pd = PantsDecomposition([[1, 2, 3], [-3, 4, 5], [4, 6, 6]], [1])
    @test boundarycurveindices(pd) == [2, 5]
    @test curveindices(pd) == [1, 2, 3, 4, 5, 6]
    @test innercurveindices(pd) == [1, 3, 4, 6]
    @test isboundary_pantscurve(pd, 2)
    @test isboundary_pantscurve(pd, -5)
    @test isinner_pantscurve(pd, -4)
    @test isinner_pantscurve(pd ,6)
    @test !istwosided_pantscurve(pd, 1)
    @test istwosided_pantscurve(pd, 3)
    @test istwosided_pantscurve(pd, -4)
    @test isonesided_pantscurve(pd, -1)
    @test !isonesided_pantscurve(pd, -6)
end

end
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
    @test_throws ErrorException isboundary_pantscurve(pd, 4)
    @test isinner_pantscurve(pd, 1)
    @test isinner_pantscurve(pd, -1)
    @test_throws ErrorException isinner_pantscurve(pd, 4)
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
    # pantend = pantscurveside_to_pantend(pd, 1, LEFT)
    # @test (pantend.pantindex, pantend.bdyindex) == (1, 1)
    # pantend = pantscurveside_to_pantend(pd, 1, RIGHT)
    # @test (pantend.pantindex, pantend.bdyindex) == (2, 3)
    # pantend = pantscurveside_to_pantend(pd, -1, LEFT)
    # @test (pantend.pantindex, pantend.bdyindex) == (2, 3)
    # pantend = pantscurveside_to_pantend(pd, -1, RIGHT)
    # @test (pantend.pantindex, pantend.bdyindex) == (1, 1)
    @test pantend_to_pantscurveside(pd, 1, 1) == (1, LEFT)
    @test pantend_to_pantscurveside(pd, 1, 2) == (2, LEFT)
    @test pantend_to_pantscurveside(pd, 1, 3) == (3, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 1) == (-3, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 2) == (-2, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 3) == (-1, LEFT)
end

@testset "Pants decomposition with one-sided curves, boundary, and orientation-reversing gluings" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, 4, 5), (4, 6, 6)], [1])
    @test collect(boundarycurveindices(pd)) == [2, 5]
    @test collect(curveindices(pd)) == [1, 2, 3, 4, 5, 6]
    @test collect(innercurveindices(pd)) == [1, 3, 4, 6]
    @test isboundary_pantscurve(pd, 2)
    @test isboundary_pantscurve(pd, -5)
    @test isinner_pantscurve(pd, -4)
    @test isinner_pantscurve(pd ,6)
    @test !istwosided_pantscurve(pd, 1)
    @test istwosided_pantscurve(pd, 3)
    @test istwosided_pantscurve(pd, -4)
    @test isonesided_pantscurve(pd, -1)
    @test !isonesided_pantscurve(pd, -6)
    @test pantend_to_pantscurveside(pd, 1, 1) == (1, LEFT)
    @test pantend_to_pantscurveside(pd, 1, 2) == (2, LEFT)
    @test pantend_to_pantscurveside(pd, 1, 3) == (3, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 1) == (-3, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 2) == (4, LEFT)
    @test pantend_to_pantscurveside(pd, 2, 3) == (5, LEFT)
    @test pantend_to_pantscurveside(pd, 3, 1) == (4, RIGHT)
    @test pantend_to_pantscurveside(pd, 3, 2) == (6, LEFT)
    @test pantend_to_pantscurveside(pd, 3, 3) == (6, RIGHT)

    @test ispantend_orientationpreserving(pd, 3, 2) != ispantend_orientationpreserving(pd, 3, 3)
    @test ispantend_orientationpreserving(pd, 2, 2) != ispantend_orientationpreserving(pd, 3, 1)
    @test ispantend_orientationpreserving(pd, 1, 3) == ispantend_orientationpreserving(pd, 2, 1)

    @test ispantscurveside_orientationpreserving(pd, 3, LEFT)
    @test ispantscurveside_orientationpreserving(pd, 3, RIGHT)
    @test ispantscurveside_orientationpreserving(pd, 6, LEFT) != ispantscurveside_orientationpreserving(pd, 6, RIGHT)
end

end
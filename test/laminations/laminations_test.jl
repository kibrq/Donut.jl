

module LaminationsTest

using Test
using Donut.Laminations
using Donut.Pants
using Donut.Constants: LEFT, RIGHT
using Donut.Utils: otherside


@testset "Lamination from pantscurve" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test lamination_from_pantscurve(pd, 1, 0) == PantsLamination{Int}(pd, [(0, 1), (0, 0), (0, 0)])
    @test lamination_from_pantscurve(pd, 2, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 1), (0, 0)])
    @test lamination_from_pantscurve(pd, 3, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 0), (0, 1)])

    pd = PantsDecomposition([(5, 2, 3), (-3, -2, -5)])
    @test lamination_from_pantscurve(pd, -5, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 0), (0, 1)])
    @test lamination_from_pantscurve(pd, -2, 0) == PantsLamination{Int}(pd, [(0, 1), (0, 0), (0, 0)])
    @test lamination_from_pantscurve(pd, -3, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 1), (0, 0)])
end

@testset "Lamination from transversal" begin
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    @test lamination_from_transversal(pd, 1, 0) == PantsLamination{Int}(pd, [(1, 0), (0, 0), (0, 0)])
    @test lamination_from_transversal(pd, 2, 0) == PantsLamination{Int}(pd, [(0, 0), (2, 0), (0, 0)])
    @test lamination_from_transversal(pd, 3, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 0), (1, 0)])

    pd = PantsDecomposition([(5, -5, 2), (-2, -3, 3)])
    @test lamination_from_transversal(pd, -5, 0) == PantsLamination{Int}(pd, [(0, 0), (0, 0), (1, 0)])
    @test lamination_from_transversal(pd, -2, 0) == PantsLamination{Int}(pd, [(2, 0), (0, 0), (0, 0)])
    @test lamination_from_transversal(pd, -3, 0) == PantsLamination{Int}(pd, [(0, 0), (1, 0), (0, 0)])
end



end
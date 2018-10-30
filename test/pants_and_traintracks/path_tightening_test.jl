module PathTighteningTest

using Test
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.PathTightening: ispathtight, reversedpath, simplifiedpath, simplifypath!
using Donut.Pants
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

# @testset "IllegalPaths" begin

@testset "Simple simplification" begin
    arc1 = construct_bridge(2, 3)
    arc2 = construct_bridge(3, -1)
    @test !ispathtight(arc1, arc2)

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, arc1, arc2) == [construct_bridge(2, -1)]

    arc3 = construct_bridge(-3, -4)
    @test ispathtight(arc1, arc3)
end

@testset "Simplify backtrackings" begin
    arc1 = construct_bridge(2, 3)
    arc2 = construct_bridge(3, 2)
    @test !ispathtight(arc1, arc2)
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test length(simplifiedpath(pd, arc1, arc2)) == 0
end

@testset "Simplify Figure 2" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_selfconnarc(1, RIGHT), construct_bridge(1, 2)) == [construct_bridge(1, 2), construct_pantscurvearc(-2)]
    @test simplifiedpath(pd, construct_selfconnarc(-3, RIGHT),
    construct_bridge(-3, -2)) ==
       [construct_bridge(-3, -2), construct_pantscurvearc(2)]
end

@testset "Simplify Figure 3" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_selfconnarc(1, RIGHT), construct_bridge(1, 3)) == [construct_pantscurvearc(1), construct_bridge(1, 3), construct_pantscurvearc(3)]
    @test simplifiedpath(pd, construct_selfconnarc(-2, RIGHT), construct_bridge(-2, -3)) == [construct_pantscurvearc(-2), construct_bridge(-2, -3), construct_pantscurvearc(-3)]
end

@testset "Simplify Figure 4" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_selfconnarc(1, LEFT),
    construct_bridge(1, 2)) ==
       [construct_bridge(1, 2),
        construct_pantscurvearc(2)]
    @test simplifiedpath(pd, construct_selfconnarc(-3, LEFT), construct_bridge(-3, -2)) ==
       [construct_bridge(-3, -2), construct_pantscurvearc(-2)]
end

@testset "Simplify Figure 5" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_bridge(2, 3), construct_pantscurvearc(-3), construct_bridge(3, 1)) == [construct_pantscurvearc(2), construct_bridge(2, 1), construct_pantscurvearc(1)]
end

@testset "Simplify Figure 6" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_bridge(2, 3), construct_pantscurvearc(-3), construct_bridge(3, 2)) == [construct_selfconnarc(2, RIGHT)]
end

@testset "Simplify Figure 7" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_bridge(2, 1), construct_pantscurvearc(-1), construct_bridge(1, 2)) == [construct_selfconnarc(2, LEFT), construct_pantscurvearc(2)]
end

@testset "Simplify Figure 8" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, construct_bridge(2, 3), construct_pantscurvearc(-3), construct_selfconnarc(3, RIGHT)) == [construct_pantscurvearc(2), construct_bridge(2, 3)]
end

@testset "Simplify long paths" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    path = [construct_bridge(1, 2),
            construct_bridge(2, 3),
            construct_pantscurvearc(3),
            construct_pantscurvearc(-3),
            construct_bridge(-3, -2),
            construct_selfconnarc(-2, LEFT),
            construct_bridge(-2, -3)]
    simplifypath!(pd, path)
    @test path == [
        construct_bridge(1, 3),
        construct_pantscurvearc(3),
        construct_selfconnarc(-3, RIGHT)
    ]

    path = [construct_bridge(3, 2),
            construct_pantscurvearc(2),
            construct_selfconnarc(-2, RIGHT),
            construct_pantscurvearc(-2),
            construct_selfconnarc(2, RIGHT),
            construct_bridge(2, 1)]

    simplifypath!(pd, path)
    @test path == [
        construct_bridge(3, 2),
        construct_pantscurvearc(2),
        construct_selfconnarc(-2, RIGHT),
        construct_bridge(2, 1),
        construct_pantscurvearc(1)
    ]
end



# end

end
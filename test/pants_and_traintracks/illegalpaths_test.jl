module IllegalPathsTest

using Test
using Donut.PantsAndTrainTracks: ispathtight, isbridgeforward, construct_pantscurvearc, reversedpath, simplifiedpath, directionof_pantscurvearc, simplifypath!, ArcInPants, pantscurvearc
using Donut.Pants
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD

# @testset "IllegalPaths" begin

@testset "Simple simplification" begin
    arc1 = ArcInPants(2, LEFT, 3, LEFT)
    arc2 = ArcInPants(3, LEFT, 1, RIGHT)
    @test !ispathtight(arc1, arc2)

    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, arc1, arc2) == [ArcInPants(2, LEFT, 1, RIGHT)]

    arc3 = ArcInPants(3, RIGHT, 4, RIGHT)
    @test ispathtight(arc1, arc3)
end

@testset "Simplify backtrackings" begin
    arc1 = ArcInPants(2, LEFT, 3, LEFT)
    arc2 = ArcInPants(3, LEFT, 2, LEFT)
    @test !ispathtight(arc1, arc2)
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, arc1, arc2) == ArcInPants[]
end

@testset "Simplify Figure 2" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(1, LEFT, 1, LEFT, RIGHT), ArcInPants(1, LEFT, 2, LEFT)) == [ArcInPants(1, LEFT, 2, LEFT), pantscurvearc(2, BACKWARD)]
    @test simplifiedpath(pd, ArcInPants(3, RIGHT, 3, RIGHT, RIGHT),
    ArcInPants(3, RIGHT, 2, RIGHT)) ==
       [ArcInPants(3, RIGHT, 2, RIGHT), pantscurvearc(2, FORWARD)]
end

@testset "Simplify Figure 3" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(1, LEFT, 1, LEFT, RIGHT), ArcInPants(1, LEFT, 3, LEFT)) == [pantscurvearc(1, FORWARD), ArcInPants(1, LEFT, 3, LEFT), pantscurvearc(3, FORWARD)]
    @test simplifiedpath(pd, ArcInPants(2, RIGHT, 2, RIGHT, RIGHT), ArcInPants(2, RIGHT, 3, RIGHT)) == [pantscurvearc(2, BACKWARD), ArcInPants(2, RIGHT, 3, RIGHT), pantscurvearc(3, BACKWARD)]
end

@testset "Simplify Figure 4" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(1, LEFT, 1, LEFT, LEFT),
    ArcInPants(1, LEFT, 2, LEFT)) ==
       [ArcInPants(1, LEFT, 2, LEFT),
        pantscurvearc(2, FORWARD)]
    @test simplifiedpath(pd, ArcInPants(3, RIGHT, 3, RIGHT, LEFT), ArcInPants(3, RIGHT, 2, RIGHT)) ==
       [ArcInPants(3, RIGHT, 2, RIGHT), pantscurvearc(2, BACKWARD)]
end

@testset "Simplify Figure 5" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(2, LEFT, 3, LEFT), pantscurvearc(3, BACKWARD), ArcInPants(3, LEFT, 1, LEFT)) == [pantscurvearc(2, FORWARD), ArcInPants(2, LEFT, 1, LEFT), pantscurvearc(1, FORWARD)]
end

@testset "Simplify Figure 6" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(2, LEFT, 3, LEFT), pantscurvearc(3, BACKWARD), ArcInPants(3, LEFT, 2, LEFT)) == [ArcInPants(2, LEFT, 2, LEFT, RIGHT)]
end

@testset "Simplify Figure 7" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(2, LEFT, 1, LEFT), pantscurvearc(1, BACKWARD), ArcInPants(1, LEFT, 2, LEFT)) == [ArcInPants(2, LEFT, 2, LEFT, LEFT), pantscurvearc(2, FORWARD)]
end

@testset "Simplify Figure 8" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    @test simplifiedpath(pd, ArcInPants(2, LEFT, 3, LEFT), pantscurvearc(3, BACKWARD), ArcInPants(3, LEFT, 3, LEFT, RIGHT)) == [pantscurvearc(2, FORWARD), ArcInPants(2, LEFT, 3, LEFT)]
end

@testset "Simplify long paths" begin
    pd = PantsDecomposition([[1, 2, 3], [-3, -2, -1]])
    path = [ArcInPants(1, LEFT, 2, LEFT),
            ArcInPants(2, LEFT, 3, LEFT),
            pantscurvearc(3, FORWARD),
            pantscurvearc(3, BACKWARD),
            ArcInPants(3, RIGHT, 2, RIGHT),
            ArcInPants(2, RIGHT, 2, RIGHT, LEFT),
            ArcInPants(2, RIGHT, 3, RIGHT)]
    simplifypath!(pd, path)
    @test path == [
        ArcInPants(1, LEFT, 3, LEFT),
        pantscurvearc(3, FORWARD),
        ArcInPants(3, RIGHT, 3, RIGHT, RIGHT)
    ]

    path = [ArcInPants(3, LEFT, 2, LEFT),
            pantscurvearc(2, FORWARD),
            ArcInPants(2, RIGHT, 2, RIGHT, RIGHT),
            pantscurvearc(2, BACKWARD),
            ArcInPants(2, LEFT, 2, LEFT, RIGHT),
            ArcInPants(2, LEFT, 1, LEFT)]

    simplifypath!(pd, path)
    @test path == [
        ArcInPants(3, LEFT, 2, LEFT),
        pantscurvearc(2, FORWARD),
        ArcInPants(2, RIGHT, 2, RIGHT, RIGHT),
        ArcInPants(2, LEFT, 1, LEFT),
        pantscurvearc(1, FORWARD)
    ]
end



# end

end
module PathTighteningTest

using Test
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.PathTightening: ispathtight, 
    simplifiedpath, simplifypath!
using Donut.Pants
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD
using Donut.PantsAndTrainTracks.Paths

# @testset "IllegalPaths" begin

@testset "Simple simplification" begin
    arc1 = BridgeArc(2, 3)
    arc2 = BridgeArc(3, -1)
    @test !ispathtight(arc1, arc2)

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, arc1, arc2) == (BridgeArc(2, -1),)

    arc3 = BridgeArc(-3, -4)
    @test ispathtight(arc1, arc3)
end

@testset "Simplify backtrackings" begin
    arc1 = BridgeArc(2, 3)
    arc2 = BridgeArc(3, 2)
    @test !ispathtight(arc1, arc2)
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test length(simplifiedpath(pd, arc1, arc2)) == 0
end

@testset "Simplify Figure 2" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, SelfConnArc(1, RIGHT), BridgeArc(1, 2)) == 
        (BridgeArc(1, 2), PantsCurveArc(-2),)
    @test simplifiedpath(pd, SelfConnArc(-3, RIGHT),
    BridgeArc(-3, -2)) ==
       (BridgeArc(-3, -2), PantsCurveArc(2),)
end

@testset "Simplify Figure 3" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, SelfConnArc(1, RIGHT), BridgeArc(1, 3)) == 
        (PantsCurveArc(1), BridgeArc(1, 3), PantsCurveArc(3),)
    @test simplifiedpath(pd, SelfConnArc(-2, RIGHT), BridgeArc(-2, -3)) == 
        (PantsCurveArc(-2), BridgeArc(-2, -3), PantsCurveArc(-3))
end

@testset "Simplify Figure 4" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, SelfConnArc(1, LEFT), BridgeArc(1, 2)) == 
        (BridgeArc(1, 2), PantsCurveArc(2))
    @test simplifiedpath(pd, SelfConnArc(-3, LEFT), BridgeArc(-3, -2)) ==
       (BridgeArc(-3, -2), PantsCurveArc(-2))
end

@testset "Simplify Figure 5" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, BridgeArc(2, 3), PantsCurveArc(-3), BridgeArc(3, 1)) == 
        (PantsCurveArc(2), BridgeArc(2, 1), PantsCurveArc(1))
end

@testset "Simplify Figure 6" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, BridgeArc(2, 3), PantsCurveArc(-3), BridgeArc(3, 2)) == 
        (SelfConnArc(2, RIGHT),)
end

@testset "Simplify Figure 7" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, BridgeArc(2, 1), PantsCurveArc(-1), BridgeArc(1, 2)) == 
        (SelfConnArc(2, LEFT), PantsCurveArc(2))
end

@testset "Simplify Figure 8" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    @test simplifiedpath(pd, BridgeArc(2, 3), PantsCurveArc(-3), SelfConnArc(3, RIGHT)) == 
        (PantsCurveArc(2), BridgeArc(2, 3))
end

@testset "Simplify long paths" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    path = Path{ArcInPants}([BridgeArc(1, 2),
            BridgeArc(2, 3),
            PantsCurveArc(3),
            PantsCurveArc(-3),
            BridgeArc(-3, -2),
            SelfConnArc(-2, LEFT),
            BridgeArc(-2, -3)])
    simplifypath!(pd, path)
    @test path.elements == [
        BridgeArc(1, 3),
        PantsCurveArc(3),
        SelfConnArc(-3, RIGHT)
    ]

    path = Path{ArcInPants}([BridgeArc(3, 2),
            PantsCurveArc(2),
            SelfConnArc(-2, RIGHT),
            PantsCurveArc(-2),
            SelfConnArc(2, RIGHT),
            BridgeArc(2, 1)])

    simplifypath!(pd, path)
    @test path.elements == [
        BridgeArc(3, 2),
        PantsCurveArc(2),
        SelfConnArc(-2, RIGHT),
        BridgeArc(2, 1),
        PantsCurveArc(1)
    ]
end



# end

end
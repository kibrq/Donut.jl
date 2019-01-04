
using Donut: ispathtight, simplifiedpath, simplifypath!, Path, PantsArc, 
    BridgeArc, PantsCurveArc, SelfConnArc, SELFCONN, BRIDGE, PANTSCURVE

@testset "Arcs" begin
    arc = BridgeArc(1, -3)
    @test reverse(arc) == BridgeArc(-3, 1)

    arc = PantsCurveArc(4)
    @test reverse(arc) == PantsCurveArc(-4)

    arc = SelfConnArc(3, RIGHT)
    @test reverse(arc) == SelfConnArc(3, LEFT)
end

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
    path = Path{PantsArc}([BridgeArc(1, 2),
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

    path = Path{PantsArc}([BridgeArc(3, 2),
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


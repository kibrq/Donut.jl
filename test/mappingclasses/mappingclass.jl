
@testset "Applying twists" begin
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    lam = lamination_from_pantscurve(pd, 2, Int(0))
    @test pantstwist(pd, 1)*lam == lam
    @test pantstwist(pd, 2)*lam == lam
    @test pantstwist(pd, 3)*lam == lam
    @test transversaltwist(pd, 1)*lam == lam
    @test transversaltwist(pd, 2)*lam == PantsLamination{Int}(pd, [(0, 0), (4, -3), (0, 0)])
    @test transversaltwist(pd, 3)*lam == lam



    # lam = lamination_from_pantscurve(pd, 1, Int(0))
    # @test transversaltwist(pd, 1)*lam == PantsLamination{Int}(pd, [(1, -1), (0, 0), (0, 0)])
    # @test transversaltwist(pd, 1, LEFT)*lam == PantsLamination{Int}(pd, [(1, 1), (0, 0), (0, 0)])
    # @test transversaltwist(pd, 2)*lam == lam
    # @test transversaltwist(pd, 3)*lam == lam 

    # lam = lamination_from_transversal(pd, 1, Int(0))
    # @test pantstwist(pd, 1)*lam == PantsLamination{Int}(pd, [(1, 1), (0, 0), (0, 0)])
    # @test pantstwist(pd, 1)^5*lam == PantsLamination{Int}(pd, [(1, 5), (0, 0), (0, 0)])
    # @test pantstwist(pd, 1, LEFT)*lam == PantsLamination{Int}(pd, [(1, -1), (0, 0), (0, 0)])
    # @test pantstwist(pd, 1, LEFT)^5*lam == PantsLamination{Int}(pd, [(1, -5), (0, 0), (0, 0)])


end

@testset "Humphries relations" begin
    A, B, c = humphries_generators(2)
    @test A[1]*A[2] == A[2]*A[1]
    @test A[1]*B[2] == B[2]*A[1]
    @test A[1]*c == c*A[1]
    @test A[1]*B[1] != B[1]*A[1]
    @test A[1]*B[1]*A[1] == B[1]*A[1]*B[1]
    @test B[1]*c == c*B[1]
    @test B[1]*B[2] == B[2]*B[1]
    @test B[1]*A[2] != A[2]*B[1]
    @test B[1]*A[2]*B[1] == A[2]*B[1]*A[2]
    @test A[2]*c == c*A[2]
    @test A[2]*B[2] != B[2]*A[2]
    @test A[2]*B[2]*A[2] == B[2]*A[2]*B[2]
    @test B[2]*c != c*B[2]
    @test B[2]*c*B[2] == c*B[2]*c
end


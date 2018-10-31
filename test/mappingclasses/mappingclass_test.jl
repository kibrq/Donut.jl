module MappingClassTest

using Test
using Donut.MappingClasses.GeneratingSets

@testset "Humphries relations" begin
    A, B, c = humphries_generators(2)
    @test A[1]*A[2] == A[2]*A[1]
    # @test A[1]*B[2] == B[2]*A[1]
    # @test A[1]*c == c*A[1]
    # @test A[1]*B[1] != B[1]*A[1]
    # @test A[1]*B[1]*A[1] == B[1]*A[1]*B[1]
    # @test B[1]*c == c*B[1]
    # @test B[1]*B[2] == B[2]*B[1]
    # @test B[1]*A[2] != A[2]*B[1]
    # @test B[1]*A[2]*B[1] == A[2]*B[1]*A[2]
    # @test A[2]*c == c*A[2]
    # @test A[2]*B[2] != B[2]*A[2]
    # @test A[2]*B[2]*A[2] == B[2]*A[2]*B[2]
    # @test B[2]*c != c*B[2]
    # @test B[2]*c*B[2] == c*B[2]*c
end



end
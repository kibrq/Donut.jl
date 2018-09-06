using Test
include("../choochoo/surf.jl")

@test_throws ErrorException Surface(-1)
@test_throws ErrorException Surface(1, -1)
@test_throws ErrorException Surface(0, 0, false)
@test_throws ErrorException surface_from_euler_char(-1, 0)
@test_throws ErrorException surface_from_euler_char(-6, 1)

@test is_orientable(Surface(0)) == true
@test is_orientable(Surface(1, 0, false)) == false

@test num_punctures(Surface(0, 0)) == 0
@test num_punctures(Surface(5, 3)) == 3

@test genus(Surface(5)) == 5
@test genus(Surface(5, 2)) == 5
@test genus(Surface(10, 2, false)) == 10
@test genus(surface_from_euler_char(-2, 2)) == 1

@test euler_char(Surface(0, 0)) == 2
@test euler_char(Surface(0, 1)) == 1
@test euler_char(Surface(1, 0)) == 0
@test euler_char(Surface(1, 0, false)) == 1
@test euler_char(Surface(2, 1, false)) == -1


@test homology_dimension(Surface(2)) == 4
@test homology_dimension(Surface(0, 1)) == 0
@test homology_dimension(Surface(0, 2)) == 1
@test homology_dimension(Surface(1, 2)) == 3
@test homology_dimension(Surface(2, 3)) == 6
@test homology_dimension(Surface(1, 0, false)) == 0
@test homology_dimension(Surface(1, 1, false)) == 1
@test homology_dimension(Surface(1, 2, false)) == 2
@test homology_dimension(Surface(2, 0, false)) == 1
@test homology_dimension(Surface(2, 1, false)) == 2
@test homology_dimension(Surface(3, 0, false)) == 2
@test homology_dimension(Surface(3, 4, false)) == 6


@test teich_space_dim(Surface(1)) == 2
@test teich_space_dim(Surface(2)) == 6
@test teich_space_dim(Surface(2, 0, false)) == 1
@test teich_space_dim(Surface(3, 1, false)) == 5
@test teich_space_dim(Surface(0)) == 0
@test teich_space_dim(Surface(0, 1)) == 0
@test teich_space_dim(Surface(0, 2)) == 0
@test teich_space_dim(Surface(0, 3)) == 0
@test teich_space_dim(Surface(0, 4)) == 2
@test teich_space_dim(Surface(0, 5)) == 4
@test teich_space_dim(Surface(1, 0, false)) == 0
@test teich_space_dim(Surface(1, 1, false)) == 0
@test teich_space_dim(Surface(1, 2, false)) == 1
@test teich_space_dim(Surface(1, 3, false)) == 3
@test teich_space_dim(Surface(2, 1, false)) == 2
@test teich_space_dim(Surface(2, 2, false)) == 4
@test teich_space_dim(Surface(3, 0, false)) == 3

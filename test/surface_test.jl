module SurfaceTest

using Test
using Donut: Surface, isorientable, numpunctures, genus, eulerchar, surface_from_eulerchar, homologydim, teichspacedim

@test_throws ErrorException Surface(-1)
@test_throws ErrorException Surface(1, -1)
@test_throws ErrorException Surface(0, 0, false)
@test_throws ErrorException surface_from_eulerchar(-1, 0)
@test_throws ErrorException surface_from_eulerchar(-6, 1)

@test isorientable(Surface(0)) == true
@test isorientable(Surface(1, 0, false)) == false

@test numpunctures(Surface(0, 0)) == 0
@test numpunctures(Surface(5, 3)) == 3

@test genus(Surface(5)) == 5
@test genus(Surface(5, 2)) == 5
@test genus(Surface(10, 2, false)) == 10
@test genus(surface_from_eulerchar(-2, 2)) == 1

@test eulerchar(Surface(0, 0)) == 2
@test eulerchar(Surface(0, 1)) == 1
@test eulerchar(Surface(1, 0)) == 0
@test eulerchar(Surface(1, 0, false)) == 1
@test eulerchar(Surface(2, 1, false)) == -1


@test homologydim(Surface(2)) == 4
@test homologydim(Surface(0, 1)) == 0
@test homologydim(Surface(0, 2)) == 1
@test homologydim(Surface(1, 2)) == 3
@test homologydim(Surface(2, 3)) == 6
@test homologydim(Surface(1, 0, false)) == 0
@test homologydim(Surface(1, 1, false)) == 1
@test homologydim(Surface(1, 2, false)) == 2
@test homologydim(Surface(2, 0, false)) == 1
@test homologydim(Surface(2, 1, false)) == 2
@test homologydim(Surface(3, 0, false)) == 2
@test homologydim(Surface(3, 4, false)) == 6


@test teichspacedim(Surface(1)) == 2
@test teichspacedim(Surface(2)) == 6
@test teichspacedim(Surface(2, 0, false)) == 1
@test teichspacedim(Surface(3, 1, false)) == 5
@test teichspacedim(Surface(0)) == 0
@test teichspacedim(Surface(0, 1)) == 0
@test teichspacedim(Surface(0, 2)) == 0
@test teichspacedim(Surface(0, 3)) == 0
@test teichspacedim(Surface(0, 4)) == 2
@test teichspacedim(Surface(0, 5)) == 4
@test teichspacedim(Surface(1, 0, false)) == 0
@test teichspacedim(Surface(1, 1, false)) == 0
@test teichspacedim(Surface(1, 2, false)) == 1
@test teichspacedim(Surface(1, 3, false)) == 3
@test teichspacedim(Surface(2, 1, false)) == 2
@test teichspacedim(Surface(2, 2, false)) == 4
@test teichspacedim(Surface(3, 0, false)) == 3


end
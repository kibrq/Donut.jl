#!/usr/bin/env julia

using Test


@time include("surface_test.jl")
@time include("traintracks/traintrack_test.jl")
@time include("pants/pantsdecomposition_test.jl")

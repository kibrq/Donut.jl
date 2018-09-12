#!/usr/bin/env julia

using Donut
using Test


println("Test Surfaces")
@time include("surface_test.jl")
println("Test TrainTracks")
@time include("traintrack_test.jl")

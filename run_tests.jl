#!/usr/bin/env julia

#Start Test Script
# using PkgName
using Test

# Run tests

# tic()
println("Test Surfaces")
@time include("test/surface_test.jl")
println("Test TrainTracks")
@time include("test/train_track_test.jl")
# toc()

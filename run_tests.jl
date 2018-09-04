#!/usr/bin/env julia

#Start Test Script
# using PkgName
using Test

# Run tests

# tic()
println("Test Surfaces")
@time include("test/surf_test.jl")
println("Test 2")
# @time @test include("../surf.jl")
# toc()

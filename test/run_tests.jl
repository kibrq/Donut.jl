#!/usr/bin/env julia

# using Test


# @time include("surface_test.jl")
# @time include("utils_test.jl")
# @time include("traintracks/all.jl")
# @time include("pants/all.jl")
@time include("pants_and_traintracks/all.jl")
@time include("laminations/laminations_test.jl")
@time include("mappingclasses/all.jl")
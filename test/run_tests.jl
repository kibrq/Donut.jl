#!/usr/bin/env julia

using Test
using Donut

include("surface.jl")
include("traintracks/basics.jl")
include("traintracks/operations.jl")
include("traintracks/measure.jl")
include("traintracks/carrying.jl")
include("markings/markings.jl")
include("markings/changeofmarkings.jl")
include("path_tightening.jl")
include("laminations/dehnthurstontracks.jl")
include("laminations/measured_dehnthurston.jl")
include("laminations/isotopy_after_elementarymove.jl")
include("laminations/peel_fold.jl")
include("laminations/laminations.jl")
include("mappingclasses/mappingclass.jl")


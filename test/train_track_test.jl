using Test
include("../strudel/train_track.jl")

@test_throws ErrorException TrainTrack([[1, 2], [-2], [-1]])
@test_throws ErrorException TrainTrack([[1, 2], [2, -1]])
@test_throws ErrorException TrainTrack([[1, 2, -2, -1], Int[]])
@test_throws ErrorException TrainTrack([[1, 2], [-2]])
@test_throws ErrorException TrainTrack([[1, 2], [-2, -3]])
@test_throws ErrorException TrainTrack([[1, 2, -2], [-2, -1, 1]])

module MeasuredDehnThurstonTest

using Test

using Donut.Pants
using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.PantsAndTrainTracks.MeasuredDehnThurstonTracks
using Donut.PantsAndTrainTracks.MeasuredDehnThurstonTracks: selfconn_and_bridge_measures

selfconn, pairs = selfconn_and_bridge_measures(1, 4, 7)
@test selfconn == [0, 0, 1]
@test pairs == [4, 1, 0]

selfconn, pairs = selfconn_and_bridge_measures(13, 10, 7)
@test selfconn == [0, 0, 0]
@test pairs == [2, 5, 8]

selfconn, pairs = selfconn_and_bridge_measures(1.0, 1.0, 1.0)
@test selfconn == [0.0, 0.0, 0.0]
@test pairs == [0.5, 0.5, 0.5]


@testset "Dehn-Thurston train track from coordinates" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, measure, encoding = measured_dehnthurstontrack(pd, [(1, -3), (4, -4), (3, 10)])

    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    tt, measure, encoding = measured_dehnthurstontrack(pd, [(5, 5), (4, 0), (3, -99)])


    pd = PantsDecomposition([(3, 2, 1), (-1, 4, 5)])
    tt, measure, encoding = measured_dehnthurstontrack(pd, [(BigInt(4), BigInt(-3))])
    @test outgoing_branch(tt, 1, 1) == -outgoing_branch(tt, -1, 1)
    @test outgoing_branch(tt, 1, 2) == -outgoing_branch(tt, 1, 3)
    @test outgoing_branch(tt, -1, 2) == -outgoing_branch(tt, -1, 3)
    @test branchmeasure(measure, outgoing_branch(tt, 1, 1)) == 3
    @test branchmeasure(measure, outgoing_branch(tt, 1, 2)) == 2
    @test branchmeasure(measure, outgoing_branch(tt, -1, 2)) == 2
end

end
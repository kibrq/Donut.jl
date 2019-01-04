using Donut: apply_change_of_marking_to_tt!

@testset "Peel-fold Dehn twist" begin
    # Twisting in the good direction
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    tt, longencodings = measured_dehnthurstontrack(pd, [(2, 1), (20, -8), (6, 14)])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 2, 4, 6, 6, 8, 8, 14]
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, Twist(2), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 2, 4, 6, 6, 8, 14, 28]

    # Twisting in the bad direction.
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    # dtcoords = DehnThurstonCoordinates{Int}([2, 20, 6], [1, -100, 14])
    tt, longencodings = measured_dehnthurstontrack(pd, [(2, 1), (20, -100), (6, 14)])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 2, 4, 6, 6, 8, 14, 100]
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, Twist(2, LEFT), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 2, 4, 6, 6, 8, 14, 80]

    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    # dtcoords = DehnThurstonCoordinates{Int}([2, 20, 6], [1, -1, 14])
    tt, longencodings = measured_dehnthurstontrack(pd, [(2, 1), (20, -1), (6, 14)])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 2, 2, 4, 6, 6, 8, 14]
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, Twist(2, LEFT), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 2, 4, 6, 6, 8, 14, 19]

end

@testset "Peel-fold second move 1" begin
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    # dtcoords = DehnThurstonCoordinates{Int}([11, 14, 8], [-100, 20, 30])
    tt, longencodings = measured_dehnthurstontrack(pd, [(11, -100), (14, 20), (8, 30)])
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(2), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [8, 8, 11, 11, 13, 13, 20, 37, 93]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(2), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 4, 7, 7, 7, 7, 20, 30, 100]
end

function separating_tt_large_central_intersection()
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    # dtcoords = DehnThurstonCoordinates{Int}([2, 20, 6], [1, -1, 14])
    tt, longencodings = measured_dehnthurstontrack(pd, [(2, 1), (20, -1), (6, 14)])
    tt, pd, longencodings, [1, 1, 2, 2, 4, 6, 6, 8, 14]
end

@testset "Peel-fold second move 2" begin
    tt, pd, longencodings, orderedmeasures = separating_tt_large_central_intersection()
    @test sort(tt.measure.values[1:numbranches(tt)]) == orderedmeasures
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(2), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(2), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == orderedmeasures
end

@testset "Peel-fold second move 3" begin
    pd = PantsDecomposition([(1, 2, 3), (-3, -2, -1)])
    # dtcoords = DehnThurstonCoordinates{Int}([2, 10, 6], [3, -11, 20])
    tt, longencodings = measured_dehnthurstontrack(pd, [(2, 3), (10, -11), (6, 20)])
    ttnet = TrainTrackNet([tt])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(3), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [2, 2, 3, 4, 10, 10, 14, 21, 22]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, SecondMove(3), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 2, 2, 3, 6, 6, 11, 20]
end



@testset "Peel-fold first move 1" begin
    """
    The following is a Dehn-Thurston train track on the genus 2 surface.
    The pants decomposition has a separating curve (2), and switch 1 is
    left-turning, switches 2 and 3 are right-turning. Pants curves 1 and 3
    give first elementary moves.

    First we test the case with lambda11 (self-connecting branch to the
    boundary of the torus. At switch 3, unzipping goes into the pants
    curves, at switch 1 it goes across.
    """
    tt, pd, longencodings, orderedmeasures = separating_tt_large_central_intersection()
    ttnet = TrainTrackNet([tt])
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(1), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 4, 6, 6, 8, 9, 9, 14]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(-3), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 6, 8, 9, 9, 10, 10, 18]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(-3, true), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 1, 4, 6, 6, 8, 9, 9, 14]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(1, true), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == orderedmeasures
end

@testset "Peel-fold first move 2" begin
    """Now testing the cases when the bridge opposite of the torus boundary is present.
    """
    pd = PantsDecomposition([(1, -1, 2), (-2, -3, 3)])
    # dtcoords = DehnThurstonCoordinates{Int}([11, 14, 8], [-100, 20, 2])
    tt, longencodings = measured_dehnthurstontrack(pd, [(11, -100), (14, 20), (8, 2)])
    ttnet = TrainTrackNet([tt])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 4, 7, 7, 7, 7, 20, 100]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(-1), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 7, 7, 7, 7, 11, 20, 93]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(3), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [2, 2, 3, 5, 7, 7, 11, 22, 93]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(-1, true), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [2, 2, 3, 4, 5, 7, 7, 22, 100]
    apply_change_of_marking_to_tt!(ttnet, 1, pd, FirstMove(3, true), longencodings, Int16[])
    @test sort(tt.measure.values[1:numbranches(tt)]) == [1, 2, 4, 7, 7, 7, 7, 20, 100]
end



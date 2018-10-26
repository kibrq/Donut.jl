

using Donut.Pants
using Donut.TrainTracks
using Donut.Pants.DTCoordinates
using Donut.PantsAndTrainTracks

struct PantsLamination{T}
    pd::PantsDecomposition
    tt::TrainTrack
    measure::Measure{T}
    encodings::Array{Array{ArcInPants, 1}, 1}

    PantsLamination{T}(pd::PantsDecomposition, dtcoords::DehnThurstonCoordinates)
        tt, measure, encodings = dehnthurstontrack(pd, dtcoords)
        new(pd, tt, measure)
    end
end

function lamination_from_pantscurve(pd::PantsDecomposition, curveindex::Int)
    dtcoords = dtcoords_of_pantscurve(pd, pantscurve)
    PantsLamination(pd, dtcoords)
end

function lamination_from_transversal(pd::PantsDecomposition, curveindex::Int)
    dtcoords = dtcoords_of_transversal(pd, pantscurve)
    PantsLamination(pd, dtcoords)
end

function twisting_number(dl::PantsLamination, curveindex::Int)
    sw = pantscurve_toswitch(dl.pd, curveindex)
    switch_turning(dl.tt, sw, dl.encodings) == LEFT ? -1 : 1) * pantscurve_measure(dl.tt, dl.measure, dl.encodings, sw)
end

function lamination_to_dtcoords(pl::PantsLamination)
    intersection_numbers = [intersecting_measure(dl.tt, dl.measure, dl.encodings, pantscurve_toswitch(dl.pd, curveindex)) for curveindex in innerindices(dl.pd)]
    twisting_numbers = [twisting_number(dl, curveindex) for curveindex in innerindices(dl.pd)]
    DehnThurstonCoordinates(intersection_numbers, twisting_numbers)
end



function apply_firstmove!(pl::PantsLamination, curveindex::Int, inverse=false)
    peel_fold_firstmove!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings, inverse)
end

function apply_secondmove!(pl::PantsLamination, curveindex::Int)
    peel_fold_secondmove!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings)
end

function apply_dehntwist!(pl::PantsLamination, curveindex::Int, twistdirection::Int)
    peel_fold_dehntwist!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings, twistdirection)
end

function apply_halftwist!(pd::PantsLamination, pantindex::Int, twistdirection::Int)
    peel_fold_halftwist!(pl.tt, pl.measure, pd.pd, curveindex, pl.encodings, twistdirection)
end
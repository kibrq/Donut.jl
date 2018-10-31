

export PantsLamination, lamination_from_pantscurve, lamination_from_transversal, lamination_to_dtcoords

using Donut.Pants
using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.Pants.DTCoordinates
using Donut.PantsAndTrainTracks.DehnThurstonTracks
using Donut.PantsAndTrainTracks.MeasuredDehnThurstonTracks
using Donut.PantsAndTrainTracks.ArcsInPants: ArcInPants
using Donut.PantsAndTrainTracks.PeelFold
using Donut.Constants: LEFT
import Base.==

struct PantsLamination{T}
    pd::PantsDecomposition
    tt::TrainTrack
    measure::Measure{T}
    encodings::Vector{ArcInPants}

    function PantsLamination{T}(pd::PantsDecomposition, dtcoords::DehnThurstonCoordinates{T}) where {T}
        tt, measure, encodings = measured_dehnthurstontrack(pd, dtcoords)
        new(pd, tt, measure, encodings)
    end
end

function Base.show(io::IO, pl::PantsLamination)
    println(io, pl.pd)
    # println(io, pl.tt)
    # println(io, pl.measure)
    # println(io, pl.encodings)
    print(io, lamination_to_dtcoords(pl))
end

function lamination_from_pantscurve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    dtcoords = dtcoords_of_pantscurve(pd, curveindex, samplenumber)
    PantsLamination{T}(pd, dtcoords)
end

function lamination_from_transversal(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    dtcoords = dtcoords_of_transversal(pd, curveindex, samplenumber)
    PantsLamination{T}(pd, dtcoords)
end

function twisting_number(pl::PantsLamination, curveindex::Int)
    sw = pantscurve_toswitch(pl.pd, curveindex)
    (switch_turning(pl.tt, sw, pl.encodings) == LEFT ? -1 : 1) * pantscurve_measure(pl.tt, pl.measure, pl.encodings, sw)
end

function lamination_to_dtcoords(pl::PantsLamination{T}) where {T}
    intersection_numbers = [intersecting_measure(pl.tt, pl.measure, pl.encodings, pantscurve_toswitch(pl.pd, curveindex)) for curveindex in innercurveindices(pl.pd)]
    twisting_numbers = [twisting_number(pl, curveindex) for curveindex in innercurveindices(pl.pd)]
    DehnThurstonCoordinates{T}(intersection_numbers, twisting_numbers)
end

function ==(pl1::PantsLamination, pl2::PantsLamination)
    coords1 = lamination_to_dtcoords(pl1)
    coords2 = lamination_to_dtcoords(pl2)
    coords1 == coords2
end

function apply_firstmove!(pl::PantsLamination, curveindex::Int, inverse=false)
    peel_fold_firstmove!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings, inverse)
end

function apply_secondmove!(pl::PantsLamination, curveindex::Int)
    peel_fold_secondmove!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings)
end

function apply_dehntwist!(pl::PantsLamination, curveindex::Int, twistdirection::Int)
    peel_fold_dehntwist!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings, otherside(twistdirection))
    # the reason we change the direction of the twisting is that twisting the train track to the LEFT is the same as twisting the marking to the RIGHT.
end

function apply_halftwist!(pl::PantsLamination, pantindex::Int, twistdirection::Int)
    peel_fold_halftwist!(pl.tt, pl.measure, pl.pd, curveindex, pl.encodings, otherside(twistdirection))
    # the reason we change the direction of the twisting is that twisting the train track to the LEFT is the same as twisting the marking to the RIGHT.
end
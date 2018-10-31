

export PantsLamination, lamination_from_pantscurve, lamination_from_transversal, lamination_to_dtcoords

using Donut.Pants
using Donut.TrainTracks
using Donut.TrainTracks.Measures
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

    function PantsLamination{T}(pd::PantsDecomposition, dtcoords::Vector{Tuple{T, T}}) where {T}
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

function coords_of_curve(pl::PantsLamination, curveindex::Int)
    if istwosided_pantscurve(pl.pd, curveindex)
        intersection_number = intersecting_measure(pl.tt, pl.measure, pl.encodings, pantscurve_toswitch(pl.pd, curveindex))
        twisting_num = twisting_number(pl, curveindex)
        return (intersection_number, twisting_num)
    else isonesided_pantscurve(pl.pd, curveindex)
        error("Dehn-Thurston coordinates for one-sided pants curves is not yet implemented.")
        # This should return a tuple with 1 element.
    end
end

function lamination_to_dtcoords(pl::PantsLamination{T}) where {T}
    [coords_of_curve(pl, c) for c in innercurveindices(pl.pd)]
end

function ==(pl1::PantsLamination, pl2::PantsLamination)
    coords1 = lamination_to_dtcoords(pl1)
    coords2 = lamination_to_dtcoords(pl2)
    coords1 == coords2
end

function zero_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    (T(0), T(0))
end

function pantscurve_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    @assert istwosided_pantscurve(pd, curveindex)
    (T(0), T(1))
end

function transvesalcurve_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    @assert istwosided_pantscurve(pd, curveindex)
    if isfirstmove_curve(pd, curveindex)
        return (T(1), T(0))
    elseif issecondmove_curve(pd, curveindex)
        return (T(2), T(0))
    else
        # TODO: Klein bottle
        @assert false
    end
end

function lamination_from_pantscurve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    construct_lamination(pd, curveindex, samplenumber, pantscurve_coords_of_curve)
end

function lamination_from_transversal(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    construct_lamination(pd, curveindex, samplenumber, transvesalcurve_coords_of_curve)
end

function construct_lamination(pd::PantsDecomposition, curveindex::Int, samplenumber::T, coord_constructor::Function) where {T}
    if !isinner_pantscurve(pd, curveindex)
        error("There is no inner pants curve of index $(curveindex).")
    end
    dtcoords = [abs(curveindex) != abs(c) ? zero_coords_of_curve(pd, c, samplenumber) : coord_constructor(pd, c, samplenumber) for c in innercurveindices(pd)]
    PantsLamination{T}(pd, dtcoords)
end


function twisting_number(pl::PantsLamination, curveindex::Int)
    sw = pantscurve_toswitch(pl.pd, curveindex)
    (switch_turning(pl.tt, sw, pl.encodings) == LEFT ? -1 : 1) * pantscurve_measure(pl.tt, pl.measure, pl.encodings, sw)
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
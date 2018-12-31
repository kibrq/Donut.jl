module TrainTrackNets

export DecoratedTrainTrack, add_cusphandler!, add_measure!, peel!, fold!, TrainTrackNet,
    get_tt

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: updatemeasure_after_ttop!
using Donut.Cusps
using Donut.Cusps: updatecusphandler_after_ttop!
using Donut.TrainTracks.Carrying
import Donut.TrainTracks.Operations: peel!, fold!, pullout_branches!, collapse_branch!

struct DecoratedTrainTrack
    tt::TrainTrack
    cusphandler::Union{CuspHandler, Nothing}
    measure::Union{Measure, Nothing}
    # Other things we could add: transverse measure, oriented measure for oriented curves     
end

DecoratedTrainTrack(tt::TrainTrack; 
    cusphandler::Union{CuspHandler, Nothing}=nothing,
    measure::Union{Measure, Nothing}=nothing) = 
        DecoratedTrainTrack(tt, cusphandler, measure)


function add_cusphandler!(dtt::DecoratedTrainTrack)
    if dtt.cusphandler != nothing
        error("The train track already has a cusphandler stored.")
    end
    dtt.cusphandler = CuspHandler(tt)
    return ch
end

function add_measure!(dtt::DecoratedTrainTrack, measure::Measure)
    if dtt.measure != nothing
        error("The train track already has a measure.")
    end
    dtt.measure = measure
end

has_measure(dtt::DecoratedTrainTrack) = dtt.measure != nothing
has_cusphandler(dtt::DecoratedTrainTrack) = dtt.cusphandler != nothing


function apply_tt_operations!(dtt::DecoratedTrainTrack, ops)
    added_sw, added_br = 0, 0
    for op in ops
        added_sw, added_br = execute_elementaryop!(dtt, op)
    end
    added_sw, added_br
end

function apply_tt_operation!(dtt::DecoratedTrainTrack, op::ElementaryTTOperation)
    added_sw, added_br = Donut.TrainTracks.Operations.execute_elementary_op!(dtt.tt, op)
    if has_measure(dtt)
        updatemeasure_after_ttop!(dtt.tt, dtt.measure, op, added_br)
    end
    if has_cusphandler(dtt)
        updatecusphandler_after_ttop!(dtt.tt, dtt.cusphandler, op, added_br)
    end
    added_sw, added_br
end


#--------------------------------------
# Convenience functions, one could just as well use apply_tt_operation! directly

function peel!(dtt::DecoratedTrainTrack, sw::Integer, side::Side)
    apply_tt_operation!(dtt, peel_op(sw, side))
end

function fold!(dtt::DecoratedTrainTrack, fold_onto_br::Integer, folded_br_side::Side)
    apply_tt_operation!(dtt, fold_op(fold_onto_br, folded_br_side))
end

function pullout_branches!(dtt::DecoratedTrainTrack, iter::BranchIterator)
    op = pullout_branches_op(iter.start_br, iter.end_br, iter.start_side)
    apply_tt_operation!(dtt, op)
end

function collapse_branch!(dtt::DecoratedTrainTrack, br::Integer)
    apply_tt_operation!(dtt, collapse_branch_op(br))
end

function renamebranch!(dtt::DecoratedTrainTrack, oldlabel::Integer, newlabel::Integer)
    apply_tt_operation!(dtt, renaming_branch_op(oldlabel, newlabel))
end

function renameswitch!(dtt::DecoratedTrainTrack, oldlabel::Integer, newlabel::Integer)
    apply_tt_operation!(dtt, renaming_switch_op(oldlabel, newlabel))
end



#--------------------------------------









struct TrainTrackNet
    tts::Vector{DecoratedTrainTrack}
    carrying_maps::Vector{Tuple{Int8, Int8, CarryingMap}} # (small_tt_index, large_tt_index, carryingmap)
end

TrainTrackNet() = TrainTrackNet(DecoratedTrainTrack[], 
                        Tuple{Int, Int, CarryingMap}[])

function add_train_track!(ttnet::TrainTrackNet, dtt::DecoratedTrainTrack)
    push!(ttnet.tts, dtt)
    return length(ttnet.tts)
end

get_tt(ttnet::TrainTrack, tt_index::Integer) = ttnet.tts[tt_index]


function add_carryingmap_as_small_tt!(ttnet::TrainTrackNet, small_tt_index::Integer)
    dtt = ttnet.tts[small_tt_index]
    ch = dtt.cusphandler
    if ch == nothing
        ch = add_cusphandler!(dtt, small_tt_index)
    end
    cm = CarryingMap(tt, ch)
    large_dtt = DecoratedTrainTrack(ch.large_tt, cusphandler=ch.large_cusphandler)
    large_tt_index = add_train_track!(ttnet, large_dtt)
    push!(ttnet.carrying_maps, (small_tt_index, large_tt_index, cm))
    return large_tt_index
end


function carrying_maps_as_small_tt(ttnet::TrainTrackNet, small_tt_index::Integer)
    (x for x in ttnet.carrying_maps if x[1] == small_tt_index)
end

function carrying_maps_as_large_tt(ttnet::TrainTrackNet, large_tt_index::Integer)
    (x for x in ttnet.carrying_maps if x[2] == large_tt_index)
end





function apply_tt_operation!(ttnet::TrainTrackNet, tt_index::Integer, 
        op::ElementaryTTOperation)

    if op.optype == PEEL
        small_fn = (cm, new_sw, new_br)->update_carryingmap_peel_small!(cm, op.label1, op.side)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_peel_large!(cm, op.label1, op.side)
    elseif op.optype == FOLD
        # Checking that the fold is possible in carrying maps where out train track
        # is a small train track.
        fold_onto_br = op.label1
        folded_br_side = op.label2
        for (small_tt_index, large_tt_index, cm) in carrying_maps_as_small_tt(ttnet, tt_index)
            is_foldable = isotope_small_tt_for_fold!(cm, fold_onto_br, folded_br_side)
            # if !is_foldable
            #     return false
            # end
            if !is_foldable
                error("The fold is not possible in the carryingmap with large "*
                    "train track of index $(large_tt_index)")
            end
        end
        small_fn = (cm, new_sw, new_br)->update_carryingmap_fold_small_after_isotopy!(cm, fold_onto_br, folded_br_side)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_fold_large!(cm, fold_onto_br, folded_br_side)
    elseif op.optype == PULLOUT_BRANCHES
        small_fn = (cm, new_sw, new_br)->update_carryingmap_pullout_branches_small!(cm, 
            BranchIterator(tt, op.label1, op.label2, op.side), new_sw, new_br)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_pullout_branches_large!(cm, 
            BranchIterator(tt, op.label1, op.label2, op.side), new_sw, new_br)
    elseif op.optype == COLLAPSE_BRANCH
        small_fn = (cm, new_sw, new_br)->update_carryingmap_collapse_branch_small!(cm, op.label1, new_sw, new_br)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_collapse_branch_large!(cm, op.label1, new_sw, new_br)
    elseif op.optype == RENAME_BRANCH
        small_fn = (cm, new_sw, new_br)->update_carryingmap_renamebranch_small!(cm, op.label1, op.label2)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_renamebranch_large!(cm, op.label1, op.label2)
    elseif op.optype == RENAME_SWITCH
        small_fn = (cm, new_sw, new_br)->update_carryingmap_renameswitch_small!(cm, op.label1, op.label2)
        large_fn = (cm, new_sw, new_br)->update_carryingmap_renameswitch_large!(cm, op.label1, op.label2)
    else
        @assert false
    end
    update_carryingmap_fn_small = small_fn
    update_carryingmap_fn_large = large_fn

    new_sw, new_br = apply_tt_operation!(get_tt(ttnet, tt_index), op)

    # TODO: Maybe do the collapse update before the operation.

    # Updating carrying maps where our tt is small.
    for (small_tt_index, large_tt_index, cm) in carrying_maps_as_small_tt(ttnet, tt_index)
        update_carryingmap_fn_small!(cm, new_sw, new_br)
    end 

    # Updating carrying maps where our tt is large.
    for (small_tt_index, large_tt_index, cm) in carrying_maps_as_large_tt(ttnet, tt_index)
        update_carryingmap_fn_large!(cm, new_sw, new_br)
    end
    return new_sw, new_br
end

function apply_tt_operations!(ttnet::TrainTrackNet, tt_index::Integer, ops)
    for op in ops
        apply_tt_operation!(ttnet, tt_index, op)
    end
end

#--------------------------------------
# Convenience functions, one could just as well use apply_tt_operation! directly

function peel!(ttnet::TrainTrackNet, tt_index::Integer, sw::Integer, side::Side)
    apply_tt_operation!(ttnet, tt_index, peel_op(sw, side))
end

function fold!(ttnet::TrainTrackNet, tt_index::Integer, fold_onto_br::Integer, folded_br_side::Side)
    apply_tt_operation!(ttnet, tt_index,, fold_op(fold_onto_br, folded_br_side))
end

function pullout_branches!(ttnet::TrainTrackNet, tt_index::Integer, iter::BranchIterator)
    op = pullout_branches_op(iter.start_br, iter.end_br, iter.start_side)
    apply_tt_operation!(ttnet, tt_index,, op)
end

function collapse_branch!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer)
    apply_tt_operation!(ttnet, tt_index,, collapse_branch_op(br))
end

function renamebranch!(ttnet::TrainTrackNet, tt_index::Integer, oldlabel::Integer, newlabel::Integer)
    apply_tt_operation!(ttnet, tt_index,, renaming_branch_op(oldlabel, newlabel))
end

function renameswitch!(ttnet::TrainTrackNet, tt_index::Integer, oldlabel::Integer, newlabel::Integer)
    apply_tt_operation!(ttnet, tt_index,, renaming_switch_op(oldlabel, newlabel))
end


#--------------------------------------
# Composite operations

function fold_trivalent!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer)
    ops = fold_trivalent_to_elementaryops(get_tt(ttnet, index), br)
    apply_tt_operations!(ttnet, tt_index, ops)
end

function split_trivalent!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer,
        left_right_or_central::TrivalentSplitType)
    ops = split_trivalent_to_elementaryops(get_tt(ttnet, index), br, 
        left_right_or_central)
    apply_tt_operations!(ttnet, tt_index, ops)
end

function reverseswitch!(ttnet::TrainTrackNet, tt_index::Integer, sw::Integer)
    ops = reverseswitch_to_elementaryops(sw)
    apply_tt_operations!(ttnet, tt_index, ops)
end

end
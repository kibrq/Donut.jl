

export TrainTrackNet, get_tt, add_traintrack!, add_carryingmap_as_small_tt!,
    apply_tt_operation!









struct TrainTrackNet
    tts::Vector{DecoratedTrainTrack}
    carrying_maps::Vector{Tuple{Int8, Int8, CarryingMap}} # (small_tt_index, large_tt_index, carryingmap)
end

TrainTrackNet() = TrainTrackNet(DecoratedTrainTrack[], 
                        Tuple{Int, Int, CarryingMap}[])
TrainTrackNet(a) = TrainTrackNet(a, Tuple{Int, Int, CarryingMap}[]) 

function add_traintrack!(ttnet::TrainTrackNet, dtt::DecoratedTrainTrack)
    push!(ttnet.tts, dtt)
    return length(ttnet.tts)
end

get_tt(ttnet::TrainTrackNet, tt_index::Integer) = ttnet.tts[tt_index]

function is_large_tt(ttnet::TrainTrackNet, tt_index::Integer)
    for (small_tt_index, large_tt_index, cm) in carrying_maps_as_large_tt(ttnet, tt_index)
        return true
    end
    return false
end

function add_carryingmap_as_small_tt!(ttnet::TrainTrackNet, small_tt_index::Integer)
    dtt = ttnet.tts[small_tt_index]
    # ch = dtt.cusphandler
    # if ch == nothing
    #     ch = add_cusphandler!(dtt, small_tt_index)
    # end
    cm = CarryingMap(dtt)
    # large_dtt = DecoratedTrainTrack(ch.large_tt, cusphandler=ch.large_cusphandler)
    large_tt_index = add_traintrack!(ttnet, cm.large_tt)
    push!(ttnet.carrying_maps, (small_tt_index, large_tt_index, cm))
    return large_tt_index, cm
end


function carrying_maps_as_small_tt(ttnet::TrainTrackNet, small_tt_index::Integer)
    (x for x in ttnet.carrying_maps if x[1] == small_tt_index)
end

function carrying_maps_as_large_tt(ttnet::TrainTrackNet, large_tt_index::Integer)
    (x for x in ttnet.carrying_maps if x[2] == large_tt_index)
end





function apply_tt_operation!(ttnet::TrainTrackNet, tt_index::Integer, 
        op::ElementaryTTOperation)
    if op isa Peel

    elseif op isa Fold
        # Checking that the fold is possible in carrying maps where out train track
        # is a small train track.
        for (small_tt_index, large_tt_index, cm) in carrying_maps_as_small_tt(ttnet, tt_index)
            is_foldable = isotope_small_tt_for_fold!(cm, op.fold_onto_br, op.folded_br_side)
            # if !is_foldable
            #     return false
            # end
            if !is_foldable
                error("The fold is not possible in the carryingmap with large "*
                    "train track of index $(large_tt_index)")
            end
        end
    end

    new_sw = apply_tt_operation!(get_tt(ttnet, tt_index), op)

    # TODO: Maybe do the collapse update before the operation.

    # Updating carrying maps where our tt is small.
    for (small_tt_index, large_tt_index, cm) in carrying_maps_as_small_tt(ttnet, tt_index)
        update_carryingmap_afterop_small!(cm, op, new_sw)
    end 

    # Updating carrying maps where our tt is large.
    for (small_tt_index, large_tt_index, cm) in carrying_maps_as_large_tt(ttnet, tt_index)
        update_carryingmap_afterop_large!(cm, op, new_sw)
    end
    return new_sw
end

function apply_tt_operation!(ttnet::TrainTrackNet, tt_index::Integer, 
        op::TTOperation)
    added_or_deleted_sw = 0
    tt = get_tt(ttnet, tt_index)
    for elem_op in convert_to_elementaryops(tt.tt, op)
        added_or_deleted_sw = apply_tt_operation!(ttnet, tt_index, elem_op)
    end
    added_or_deleted_sw
end



function make_small_tt_trivalent!(ttnet::TrainTrackNet, tt_index::Integer)
    tt = get_tt(ttnet, tt_index)
    tt_switches = collect(switches(tt))
    # we collect, because iterating on the iterator is dangerous, since
    # the internals of the train track change during the iteration.

    for sw in tt_switches
        valence = switchvalence(tt, sw)
        num_pulls = valence - 3
        @assert num_pulls >= 0
        if num_pulls == 0
            return
        end
        for sgn in (1, -1)
            br = extremal_branch(tt, sgn*sw, LEFT)
            while true
                prev_br = br
                br = next_branch(tt, br, RIGHT)
                if br != 0
                    new_sw = apply_tt_operation!(ttnet, tt_index, 
                        PulloutBranches(prev_br, br, LEFT))
                    new_br = new_branch_after_pullout(tt.tt, new_sw)
                    num_pulls -= 1
                    if num_pulls == 0
                        return
                    end
                    br = new_br
                else
                    # No more branches
                    break
                end
            end
        end
        # When should get here, since there should be enough branches to 
        # pull out to reduce the valence to 3.
        @assert false
    end
end

function whichside_to_peel(ttnet::TrainTrackNet, tt_index::Integer,
        sw::Integer, side::Side)
    tt = get_tt(ttnet, tt_index)
    if !is_large_tt(ttnet, tt_index)
        @assert hasmeasure(tt)
        return whichside_to_peel(tt.tt, tt.measure, sw, side)
    else
        error("Not yet implemented")
    end
end



# function apply_tt_operations!(ttnet::TrainTrackNet, tt_index::Integer, ops)
#     for op in ops
#         apply_tt_operation!(ttnet, tt_index, op)
#     end
# end

#--------------------------------------
# Convenience functions, one could just as well use apply_tt_operation! directly

# function peel!(ttnet::TrainTrackNet, tt_index::Integer, sw::Integer, side::Side)
#     apply_tt_operation!(ttnet, tt_index, peel_op(sw, side))
# end

# function fold!(ttnet::TrainTrackNet, tt_index::Integer, fold_onto_br::Integer, folded_br_side::Side)
#     apply_tt_operation!(ttnet, tt_index,, fold_op(fold_onto_br, folded_br_side))
# end

# function pullout_branches!(ttnet::TrainTrackNet, tt_index::Integer, iter::BranchIterator)
#     op = pullout_branches_op(iter.start_br, iter.end_br, iter.start_side)
#     apply_tt_operation!(ttnet, tt_index,, op)
# end

# function collapse_branch!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer)
#     apply_tt_operation!(ttnet, tt_index,, collapse_branch_op(br))
# end

# function renamebranch!(ttnet::TrainTrackNet, tt_index::Integer, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(ttnet, tt_index,, renaming_branch_op(oldlabel, newlabel))
# end

# function renameswitch!(ttnet::TrainTrackNet, tt_index::Integer, oldlabel::Integer, newlabel::Integer)
#     apply_tt_operation!(ttnet, tt_index,, renaming_switch_op(oldlabel, newlabel))
# end


#--------------------------------------
# Composite operations

# function fold_trivalent!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer)
#     ops = fold_trivalent_to_elementaryops(get_tt(ttnet, index), br)
#     apply_tt_operations!(ttnet, tt_index, ops)
# end

# function split_trivalent!(ttnet::TrainTrackNet, tt_index::Integer, br::Integer,
#         left_right_or_central::TrivalentSplitType)
#     ops = split_trivalent_to_elementaryops(get_tt(ttnet, index), br, 
#         left_right_or_central)
#     apply_tt_operations!(ttnet, tt_index, ops)
# end

# function reverseswitch!(ttnet::TrainTrackNet, tt_index::Integer, sw::Integer)
#     ops = reverseswitch_to_elementaryops(sw)
#     apply_tt_operations!(ttnet, tt_index, ops)
# end

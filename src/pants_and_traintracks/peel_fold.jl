
module PeelFold

export apply_change_of_marking_to_tt!


using Donut.TrainTracks
using Donut.TrainTracks: whichside_to_peel
using Donut.Pants
using Donut.PantsAndTrainTracks.PathTightening
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.ArcsInPants: pantscurvearc_direction
using Donut.PantsAndTrainTracks.IsotopyAfterElementaryMoves
using Donut.Constants



debug = false

function is_switchside_legal(tt::DecoratedTrainTrack, sw::Integer, side::Side, 
        encodings::Vector{ArcInPants}, encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}})
    debug = false
    frontbr = extremal_branch(tt, sw, side)
    backbr = extremal_branch(tt, -sw, otherside(side))
    frontenc = branch_to_path(encodings, encoding_changes, frontbr)
    backenc = branch_to_path(encodings, encoding_changes, backbr)
    if debug
        println("------------------ BEGIN: is_switchside_legal")
        println("Switch: ", sw)
        println("Side: ", side)
        println("Front br: ", frontbr)
        println("Back br: ", backbr)
        println("Front encoding: ", frontenc)
        println("Back encoding: ", backenc)
        println("------------------ END: is_switchside_legal")
    end

    if !ispathtight(reversed(frontenc[1]), backenc[1])
        return false
    elseif length(frontenc) > 1 && !ispathtight(reversed(backenc[1]), frontenc[1], frontenc[2])
        return false
    elseif length(backenc) > 1 && !ispathtight(reversed(frontenc[1]), backenc[1], backenc[2])
        return false
    end
    true
end

function branch_to_path(encodings::Vector{ArcInPants}, encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, branch::Integer)
    for (br, enc_arr) in encoding_changes
        @assert br > 0
        if br == abs(branch)
            return branch > 0 ? enc_arr : reversedpath(enc_arr)
        end
    end
    branch > 0 ? [encodings[branch]] : [reversed(encodings[-branch])]
end

function branch_to_arc(encodings::Vector{ArcInPants}, branch::Integer)
    branch > 0 ? encodings[branch] : reversed(encodings[-branch])
end

function add_path!(encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, addto_br::Integer, added_br::Integer)
    added_branches = branch_to_path(encodings, encoding_changes, added_br)
    for (br, enc_arr) in encoding_changes
        if br == abs(addto_br)
            if addto_br > 0
                append!(enc_arr, added_branches)
            else
                splice!(enc_arr, 1:0, reversedpath(added_branches))
            end
            return
        end
    end
    new_encoding = [encodings[abs(addto_br)]]
    if addto_br > 0
        append!(new_encoding, added_branches)
    else
        splice!(new_encoding, 1:0, reversedpath(added_branches))
    end
    push!(encoding_changes, (abs(addto_br), new_encoding))
end

function printencoding(encodings)
    for i in eachindex(encodings)
        println(i, ": ", encodings[i])
    end
end

function printencoding_changes(encoding_changes)
    for (br, enc_arr) in encoding_changes
        println(br, ": ", enc_arr)
    end
end

function peel_to_remove_illegalturns!(ttnet::TrainTrackNet, tt_index::Integer,
        pd::PantsDecomposition, encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}})
    tt = get_tt(ttnet, tt_index)
    switches_toconsider = Set(abs(branch_endpoint(tt, sg*br)) 
        for (br, enc_arr) in encoding_changes for sg in (1, -1))

    for i in length(encoding_changes):-1:1
        br, enc_arr = encoding_changes[i]
        @assert br > 0
        if length(enc_arr) == 1
            store_length1_path!(encodings, encoding_changes, i)
        end
    end

    if debug
        println("***************** START PEELING! **************")
        println("Switches to consider: ", switches_toconsider)
        println("Encodings:")
        printencoding(encodings)
        printencoding_changes(encoding_changes)
    end
    if debug
        println("Pants decomposition: ", pd)
        println("TrainTrack gluing list: ", tt_gluinglist(tt))
        # println("TrainTrack: ", tt)
        println("Encodings: ")
        printencoding(encodings)
        printencoding_changes(encoding_changes)
        println()
    end
    illegalturn_found = true
    while illegalturn_found
        illegalturn_found = false
        for sw in switches_toconsider
            for side in (LEFT, RIGHT)
                if debug
                    println(is_switchside_legal(tt, sw, side, encodings, encoding_changes))
                end
                if !is_switchside_legal(tt, sw, side, encodings, encoding_changes)
                    if debug
                        println("------------------ BEGIN: peel_loop")
                    end

                    peeledbr = extremal_branch(tt, sw, side)
                    otherbr = extremal_branch(tt, -sw, otherside(side))
     
                    sidetopeel = whichside_to_peel(ttnet, tt_index, sw, side)
                    if sidetopeel == FORWARD
                        apply_tt_operation!(ttnet, tt_index, Peel(sw, side))
                    else
                        peeledbr, otherbr = otherbr, peeledbr
                        apply_tt_operation!(ttnet, tt_index, Peel(-sw, otherside(side)))
                    end
                    if debug
                        println("Peeling $(peeledbr) off of $(otherbr)...")
                        println("TrainTrack: ", tt_gluinglist(tt))
                        # println("Switch:", sw)
                        # println("Side:", side)
                        println("Encoding before peeling:")
                        printencoding(encodings)
                        printencoding_changes(encoding_changes)
                    end

                    add_path!(encodings, encoding_changes, -peeledbr, otherbr)

                    if debug
                        println("Encoding of peeled branch ($(peeledbr)) after peeling:", branch_to_path(encodings, encoding_changes, peeledbr))
                    end
                    # printencoding_changes(encoding_changes)

                    for i in eachindex(encoding_changes)
                        br, enc_arr = encoding_changes[i]
                        @assert br > 0
                        if br == abs(peeledbr)
                            simplifypath!(pd, enc_arr)
                            if length(enc_arr) == 1
                                store_length1_path!(encodings, encoding_changes, i)
                            end
                            break
                        end
                    end
                    # printencoding_changes(encoding_changes)

                    if debug
                        println("Encoding of peeled branch ($(peeledbr)) after simpifying:", branch_to_path(encodings, encoding_changes, peeledbr))
                        println("------------------ END: peel_loop")
                    end
                    # printencoding_changes(encoding_changes)

                    illegalturn_found = true
                    break
                end
            end
            if illegalturn_found
                break
            end
        end
    end
    if debug
        println("***************** END PEELING! **************")
        println()
        println()
    end
    return switches_toconsider
end

function issubpath(encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, 
        br1::Integer, br2::Integer)
    path1 = branch_to_path(encodings, encoding_changes, br1)
    path2 = branch_to_path(encodings, encoding_changes, br2)
    if length(path1) > length(path2)
        return false
    end
    all(path1[i] == path2[i] for i in eachindex(path1))
end

function subtract_path!(encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, subtract_from_br::Integer, 
        subtracted_br::Integer)
    @assert issubpath(encodings, encoding_changes, subtracted_br, subtract_from_br)
    subtracted_enc = branch_to_path(encodings, encoding_changes, subtracted_br)

    for i in eachindex(encoding_changes)
        br, enc_arr = encoding_changes[i]
        if br == abs(subtract_from_br)
            if subtract_from_br > 0
                splice!(enc_arr, 1:length(subtracted_enc), [])
            else
                len1 = length(enc_arr)
                len2 = length(subtracted_enc)
                splice!(enc_arr, len1-len2+1:len1, [])
            end
            if length(enc_arr) == 1
                store_length1_path!(encodings, encoding_changes, i)
            end
            return
        end
    end
end

function store_length1_path!(encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, changeindex::Integer)
    br, enc_arr = encoding_changes[changeindex]
    @assert length(enc_arr) == 1
    encodings[br] = enc_arr[1]
    deleteat!(encoding_changes, changeindex)
end


function fold_peeledtt_back!(ttnet::TrainTrackNet, tt_index::Integer, 
        encodings::Vector{ArcInPants}, 
        encoding_changes::Vector{Tuple{Int16, Vector{ArcInPants}}}, 
        switches_toconsider::Set{Int16})
    tt = get_tt(ttnet, tt_index)
    # switches to consider for fixing the switch orientations.
    if debug
        println("***************** START FOLDING! **************")
    end
    # switches_to_fix = Set(abs(branch_endpoint(tt, sg*br)) for (br, _) in encoding_changes for sg in (-1,1))

    count = 0
    while length(encoding_changes) > 0 && count < 10
        count += 1
        if debug
            println("TrainTrack gluing list: ", tt_gluinglist(tt))
            # println("TrainTrack: ", tt)
            println("Encodings: ")
            printencoding(encodings)
            printencoding_changes(encoding_changes)
            println()
        end
        for i in length(encoding_changes):-1:1
            br, _ = encoding_changes[i]
            foldfound = false
            for sg in (-1, 1)
                signed_br = sg*br
                start_sw = branch_endpoint(tt, -signed_br)
                for side in (LEFT, RIGHT)
                    if extremal_branch(tt, start_sw, otherside(side)) == signed_br
                        # there is nothing on the otherside of signed_br, so we
                        # cannot fold
                        continue
                    end
                    # end_sw = branch_endpoint(tt, signed_br)
                    # if extremal_branch(tt, end_sw, side)

                    fold_onto_br = next_branch(tt, signed_br, otherside(side))
                    if issubpath(encodings, encoding_changes, fold_onto_br, signed_br)
                        if debug
                            println("Folding $(signed_br) onto $(fold_onto_br)...")
                        end
                        endsw = branch_endpoint(tt, fold_onto_br)
                        
                        apply_tt_operation!(ttnet, tt_index, Fold(fold_onto_br, side))
                        subtract_path!(encodings, encoding_changes, signed_br, fold_onto_br)
                        if debug
                            println("TrainTrack gluing list: ", tt_gluinglist(tt))
                            # println("TrainTrack: ", tt)
                            println("Encodings: ")
                            printencoding(encodings)
                            printencoding_changes(encoding_changes)
                            println()
                        end
                        foldfound = true
                        break
                    end
                end
                if foldfound
                    break
                end
            end
        end
    end
    if debug
        println("***************** END FOLDING! **************")
        println()
        println()
    end
    @assert length(encoding_changes) == 0

    # Fixing switch orientations.
    # println("Fixing orie  ntation of switches ", switches_toconsider, "...")
    for sw in switches_toconsider
        fix_switch_orientation!(ttnet, tt_index, sw, encodings)
    end
end

function fix_switch_orientation!(ttnet::TrainTrackNet, tt_index::Integer,
        sw::Integer, encodings::Vector{ArcInPants})
    # println(encodings)
    # println(outgoing_branches(tt, sw))
    # println(outgoing_branches(tt, -sw))
    tt = get_tt(ttnet, tt_index)
    @assert sw > 0
    for side in (LEFT, RIGHT)
        br = extremal_branch(tt, sw, side)
        arc = branch_to_arc(encodings, br)
        if ispantscurvearc(arc)
            if pantscurvearc_direction(arc) == BACKWARD
                apply_tt_operation!(ttnet, tt_index, ReverseSwitch(sw))
            end
            return
        end
    end
    @assert false
end


function apply_change_of_marking_to_tt!(ttnet::TrainTrackNet, 
        tt_index::Integer, pd::PantsDecomposition, move::ChangeOfPantsMarking, 
        encodings::Vector{ArcInPants})
    tt = get_tt(ttnet, tt_index)
    encoding_changes = update_encodings_aftermove!(tt, pd, move, encodings)
    switches_toconsider = peel_to_remove_illegalturns!(ttnet, tt_index, pd,
        encodings, encoding_changes)
    fold_peeledtt_back!(ttnet, tt_index, encodings, encoding_changes, switches_toconsider)
end

# function peelfold_after_elementarymove!(ttnet::TrainTrackNet, tt_index::Integer, 
#         pd::PantsDecomposition, move::ChangeOfPantsMarking, encodings::Vector{ArcInPants})
#     tt = get_tt(ttnet, tt_index)
#     encoding_changes = update_encodings_aftermove!(tt, pd, move.curveindex, encodings)
#     switches_toconsider = peel_to_remove_illegalturns!(ttnet, tt_index, pd,
#         encodings, encoding_changes)
#     fold_peeledtt_back!(ttnet, tt_index, encodings, encoding_change, switches_toconsider)
# end


# function peel_fold_secondmove!(ttnet::TrainTrackNet, tt_index::Integer, 
#         pd::PantsDecomposition, curveindex::Integer, encodings::Vector{ArcInPants})
#     peel_fold_elementarymove!(ttnet, tt_index, pd, 
#         (tt, pd, encodings)->update_encodings_after_secondmove!(tt, pd, curveindex, 
#         encodings), encodings)
# end

# function peel_fold_firstmove!(ttnet::TrainTrackNet, tt_index::Integer, 
#         pd::PantsDecomposition, curveindex::Integer, 
#         encodings::Vector{ArcInPants}, is_inverse=false)
#     peel_fold_elementarymove!(ttnet, tt_index, pd, 
#         (tt, pd, encodings)->update_encodings_after_firstmove!(tt, pd, curveindex, 
#         encodings, is_inverse), encodings)
# end




# function peel_fold_aftermove!(ttnet::TrainTrackNet, tt_index::Integer, 
#         pd::PantsDecomposition, move::Twist, encodings::Vector{ArcInPants})
#     pantindex = pant_nextto_pantscurve(pd, move.curveindex, LEFT)
#     bdyindex = bdyindex_nextto_pantscurve(pd, move.curveindex, LEFT)

    
#     peel_fold_elementarymove!(ttnet, tt_index, pd, (
#         tt, pd, encodings)->update_encodings_after_dehntwist!(tt, pd, pantindex, 
#         bdyindex, twistdirection, encodings), encodings)
# end


# function peel_fold_halftwist!(ttnet::TrainTrackNet, tt_index::Integer, pd::PantsDecomposition, 
#         curveindex::Integer, encodings::Vector{ArcInPants}, twistdirection::Side)
#     pantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
#     bdyindex = bdyindex_nextto_pantscurve(pd, curveindex, LEFT)
#     peel_fold_elementarymove!(ttnet, tt_index, pd, 
#         (tt, pd, encodings)->update_encodings_after_halftwist!(tt, pd, pantindex, 
#         bdyindex, twistdirection, encodings), encodings)
# end



end
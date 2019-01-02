
module PeelFold

export apply_change_of_marking_to_tt!


using Donut.TrainTracks
using Donut.TrainTracks: whichside_to_peel
using Donut.Pants
using Donut.PantsAndTrainTracks.PathTightening
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.IsotopyAfterElementaryMoves
using Donut.Constants
using Donut.PantsAndTrainTracks.Paths
using Donut.PantsAndTrainTracks.DehnThurstonTracks: encoding_of_length1_branch



debug = false

function is_switchside_legal(tt::DecoratedTrainTrack, sw::Integer, side::Side, 
        encodings::Vector{Path{ArcInPants}})
    debug = false
    frontbr = extremal_branch(tt, sw, side)
    backbr = extremal_branch(tt, -sw, otherside(side))
    frontenc = branch_to_path(encodings, frontbr)
    backenc = branch_to_path(encodings, backbr)
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

    if !ispathtight(reverse(frontenc[1]), backenc[1])
        return false
    elseif length(frontenc) > 1 && !ispathtight(reverse(backenc[1]), frontenc[1], frontenc[2])
        return false
    elseif length(backenc) > 1 && !ispathtight(reverse(frontenc[1]), backenc[1], backenc[2])
        return false
    end
    true
end

function branch_to_path(encodings::Vector{Path{ArcInPants}}, br::Integer)
    br > 0 ? encodings[br] : reverse(encodings[-br])
end


function printencoding(encodings)
    for i in eachindex(encodings)
        println(i, ": ", encodings[i])
    end
end


function peel_to_remove_illegalturns!(ttnet::TrainTrackNet, tt_index::Integer,
        pd::PantsDecomposition, encodings::Vector{Path{ArcInPants}}, 
        branches_to_change::Vector{Int16})
    tt = get_tt(ttnet, tt_index)

    # We are allocating memory here. If this becomes a bottleneck, we can
    # make use it more efficient.
    switches_toconsider = Set(abs(branch_endpoint(tt, sg*br)) 
        for br in branches_to_change for sg in (1, -1))
    longer_than1_branches = Set(abs(br) for br in branches_to_change if 
        length(encodings[abs(br)]) > 1)

    if debug
        println("***************** START PEELING! **************")
        println("Switches to consider: ", switches_toconsider)
        # println("Encodings:")
        # printencoding(encodings)
    end
    if debug
        println("Pants decomposition: ", pd)
        println(tt)
        # println("TrainTrack: ", tt)
        println("Encodings: ")
        printencoding(encodings)
        println("Branches longer than 1: ", longer_than1_branches)
        println()
    end
    illegalturn_found = true
    while illegalturn_found
        illegalturn_found = find_illegal_turn_and_peel!(ttnet, tt_index,
        pd, encodings, switches_toconsider, longer_than1_branches)
    end
    if debug
        println("***************** END PEELING! **************")
        println()
        println()
    end
    return switches_toconsider, longer_than1_branches
end


function find_illegal_turn_and_peel!(ttnet::TrainTrackNet, tt_index::Integer,
    pd::PantsDecomposition, encodings::Vector{Path{ArcInPants}}, 
    switches_toconsider::Set{Int16}, longer_than1_branches::Set{Int16})
    tt = get_tt(ttnet, tt_index)
    for sw in switches_toconsider
        for side in (LEFT, RIGHT)
            if debug
                println(is_switchside_legal(tt, sw, side, encodings))
            end
            if !is_switchside_legal(tt, sw, side, encodings)
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
                    println("TrainTrack: ", tt)
                    # println("Switch:", sw)
                    # println("Side:", side)
                    
                    println("Encoding before peeling:")
                    printencoding(encodings)
                    # printencoding_changes(encoding_changes)
                end

                append!(branch_to_path(encodings, -peeledbr), 
                    branch_to_path(encodings, otherbr))

                if debug
                    println("Encoding of peeled branch ($(peeledbr)) after peeling:", 
                        branch_to_path(encodings, peeledbr))
                end
                # printencoding_changes(encoding_changes)
                path = branch_to_path(encodings, peeledbr)
                simplifypath!(pd, path)

                if length(path) == 1
                    # if a path became length 1, we don't keep track anymore
                    delete!(longer_than1_branches, abs(peeledbr))
                else
                    # if longer than 1, we keep track
                    push!(longer_than1_branches, abs(peeledbr))
                end


                # printencoding_changes(encoding_changes)

                if debug
                    println("Encoding of peeled branch ($(peeledbr)) after simpifying:", 
                        branch_to_path(encodings, peeledbr))
                    println("Branches longer than 1: ", longer_than1_branches)
                    println("------------------ END: peel_loop")
                end
                # printencoding_changes(encoding_changes)
                return true
            end
        end
    end
    return false
end



function issubpath(encodings::Vector{Path{ArcInPants}}, 
        br1::Integer, br2::Integer)
    path1 = branch_to_path(encodings, br1)
    path2 = branch_to_path(encodings, br2)
    if length(path1) > length(path2)
        return false
    end
    # println(path1)
    # println(path2)
    # println(    all(path1[i] == path2[i] for i in 1:length(path1))      )
    all(path1[i] == path2[i] for i in 1:length(path1))
end


function fold_peeledtt_back!(ttnet::TrainTrackNet, tt_index::Integer, 
        encodings::Vector{Path{ArcInPants}}, 
        switches_toconsider::Set{Int16}, longer_than1_branches::Set{Int16})
    tt = get_tt(ttnet, tt_index)
    # switches to consider for fixing the switch orientations.
    if debug
        println("***************** START FOLDING! **************")
    end
    # switches_to_fix = Set(abs(branch_endpoint(tt, sg*br)) for (br, _) in encoding_changes for sg in (-1,1))

    count = 0
    # println(longer_than1_branches)
    while length(longer_than1_branches) > 0 && count < 10
        count += 1
        if debug
            println(tt)
            # println("TrainTrack: ", tt)
            println("Encodings: ")
            printencoding(encodings)
            # printencoding_changes(encoding_changes)
            println()
        end
        for br in longer_than1_branches
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
                    if issubpath(encodings, fold_onto_br, signed_br)
                        if debug
                            println("Folding $(signed_br) onto $(fold_onto_br)...")
                        end
                        endsw = branch_endpoint(tt, fold_onto_br)
                        
                        apply_tt_operation!(ttnet, tt_index, Fold(fold_onto_br, side))

                        subtract!(branch_to_path(encodings, signed_br), 
                            branch_to_path(encodings, fold_onto_br))
                        # if a path became length 1, we don't keep track anymore
                        path = branch_to_path(encodings, signed_br)
                        if length(path) == 1
                            delete!(longer_than1_branches, br)
                        end
                        # println(longer_than1_branches)
                        if debug
                            println(tt)
                            # println("TrainTrack: ", tt)
                            println("Encodings: ")
                            printencoding(encodings)
                            # printencoding_changes(encoding_changes)
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
    # println(longer_than1_branches)
    @assert length(longer_than1_branches) == 0

    # Fixing switch orientations.
    # println("Fixing orie  ntation of switches ", switches_toconsider, "...")
    # for sw in switches_toconsider
    #     fix_switch_orientation!(ttnet, tt_index, sw, encodings)
    # end
end




# function fix_switch_orientation!(ttnet::TrainTrackNet, tt_index::Integer,
#         sw::Integer, encodings::Vector{Path{ArcInPants}})
#     # println(encodings)
#     # println(outgoing_branches(tt, sw))
#     # println(outgoing_branches(tt, -sw))
#     tt = get_tt(ttnet, tt_index)
#     @assert sw > 0
#     for side in (LEFT, RIGHT)
#         br = extremal_branch(tt, sw, side)
#         arc = encoding_of_length1_branch(encodings, br)
#         if arc isa PantsCurveArc
#             if direction_of_pantscurvearc(arc) == BACKWARD
#                 apply_tt_operation!(ttnet, tt_index, ReverseSwitch(sw))
#             end
#             return
#         end
#     end
#     @assert false
# end


function apply_change_of_marking_to_tt!(ttnet::TrainTrackNet, 
        tt_index::Integer, pd::PantsDecomposition, move::ChangeOfPantsMarking, 
        encodings::Vector{Path{ArcInPants}}, branches_to_change::Vector{Int16})
    tt = get_tt(ttnet, tt_index)
    update_encodings_aftermove!(tt, pd, move, encodings, branches_to_change)
    switches_toconsider, longer_than1_branches = 
        peel_to_remove_illegalturns!(ttnet, tt_index, pd, encodings, branches_to_change)
    fold_peeledtt_back!(ttnet, tt_index, encodings, switches_toconsider,
        longer_than1_branches)
end


end
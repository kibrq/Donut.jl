

using Donut.TrainTracks.MeasuresAndOperations
using Donut.TrainTracks
import Donut
import Donut.TrainTracks.Operations


function is_switchside_legal(tt::TrainTrack, sw::Int, side::Int, encodings::Array{Array{ArcInPants, 1}, 1})
    debug = false
    frontbr = outgoing_branch(tt, sw, 1, side)
    backbr = outgoing_branch(tt, -sw, 1, otherside(side))
    frontenc = encoding_of_branch(encodings, frontbr)
    backenc = encoding_of_branch(encodings, backbr)
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

function encoding_of_branch(encodings::Array{Array{ArcInPants, 1}, 1}, br::Int)
    br > 0 ? encodings[br] : reversedpath(encodings[-br])
end

function add_encoding!(encodings::Array{Array{ArcInPants, 1}, 1}, addto_br::Int, added_br::Int)
    if addto_br > 0
        append!(encodings[addto_br], encoding_of_branch(encodings, added_br))
    else
        splice!(encodings[-addto_br], 1:0, reversedpath(encoding_of_branch(encodings, added_br)))
    end
end

function printencoding(encodings)
    for i in eachindex(encodings)
        println(i, ": ", encodings[i])
    end
end

function peel_to_remove_illegalturns!(tt::TrainTrack, pd::PantsDecomposition, encodings::Array{Array{ArcInPants, 1}, 1}, measure::Measure, switches_toconsider::AbstractArray{Int}=Int[], debug=false)
    if length(switches_toconsider) == 0
        switches_toconsider = collect(1:length(switches(tt)))
    end
    # switches_left = copy(switches_toconsider)
    if debug
        println("***************** START PEELING! **************")
        println("Switches to consider: ", switches_toconsider)
        println("Encodings:")
        printencoding(encodings)
    end
    if debug
        println("TrainTrack gluing list: ", tt_gluinglist(tt))
        # println("TrainTrack: ", tt)
        println("Encodings: ")
        printencoding(encodings)
        println()
    end
    illegalturn_found = true
    while illegalturn_found
        illegalturn_found = false
        for sw in switches_toconsider
            for side in (LEFT, RIGHT)
                if debug
                    println(is_switchside_legal(tt, sw, side, encodings))
                end
                if !is_switchside_legal(tt, sw, side, encodings)
                    if debug
                        println("------------------ BEGIN: peel_loop")
                    end
                    sidetopeel = whichside_to_peel(tt, measure, sw, side)
                    peeledbr = outgoing_branch(tt, sw, 1, side)
                    otherbr = outgoing_branch(tt, -sw, 1, otherside(side))
                    if sidetopeel == FORWARD
                        peel!(tt, sw, side, measure)
                    else
                        peeledbr, otherbr = otherbr, peeledbr
                        peel!(tt, -sw, otherside(side), measure)
                    end
                    if debug
                        println("Peeling $(peeledbr) off of $(otherbr)...")
                        println("TrainTrack: ", tt_gluinglist(tt))
                        # println("Switch:", sw)
                        # println("Side:", side)
                        println("Encoding before peeling:")
                        printencoding(encodings)
                    end

                    add_encoding!(encodings, -peeledbr, otherbr)

                    if debug
                        println("Encoding of peeled branch ($(peeledbr)) after peeling:", encoding_of_branch(encodings, peeledbr))
                    end

                    simplifypath!(pd, encodings[abs(peeledbr)])

                    if debug
                        println("Encoding of peeled branch ($(peeledbr)) after simpifying:", encoding_of_branch(encodings, peeledbr))
                        println("------------------ END: peel_loop")
                    end

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
end

function issubpath(encodings::Array{Array{ArcInPants, 1}, 1}, br1::Int, br2::Int)
    path1 = encoding_of_branch(encodings, br1)
    path2 = encoding_of_branch(encodings, br2)
    if length(path1) > length(path2)
        return false
    end
    all(path1[i] == path2[i] for i in eachindex(path1))
end

function subtract_encoding!(encodings::Array{Array{ArcInPants, 1}, 1}, subtract_from_br::Int, subtracted_br::Int)
    @assert issubpath(encodings, subtracted_br, subtract_from_br)
    if subtract_from_br > 0
        splice!(encodings[subtract_from_br], 1:length(encoding_of_branch(encodings, subtracted_br)), [])
    else
        len1 = length(encodings[-subtract_from_br])
        len2 = length(encoding_of_branch(encodings, subtracted_br))
        splice!(encodings[-subtract_from_br], len1-len2+1:len1, [])
    end
end


function fold_peeledtt_back!(tt::TrainTrack, measure::Measure, encodings::Array{Array{ArcInPants, 1}, 1}, branches_toconsider::AbstractArray{Int, 1}=Int[], debug=false)
    if debug
        println("***************** START FOLDING! **************")
    end
    if length(branches_toconsider) == 0
        branches_toconsider = [br for br in branches(tt) if length(encoding_of_branch(encodings, br)) > 1]
    end
    branches_left = copy(branches_toconsider)
    for i in length(branches_left):-1:1
        br = branches_left[i]
        if length(encoding_of_branch(encodings, br)) == 1                
            deleteat!(branches_left, i) 
        end
    end
    count = 0
    while length(branches_left) > 0 && count < 20
        count += 1
        if debug
            println("TrainTrack gluing list: ", tt_gluinglist(tt))
            # println("TrainTrack: ", tt)
            println("Encodings: ")
            printencoding(encodings)
            println()
        end
        for i in length(branches_left):-1:1
            br = branches_left[i]
            foldfound = false
            for sg in (-1, 1)
                signed_br = sg*br
                start_sw = branch_endpoint(tt, -signed_br)
                for side in (LEFT, RIGHT)
                    if outgoing_branch(tt, start_sw, 1, side) == signed_br
                        continue
                    end

                    index = outgoing_branch_index(tt, start_sw, signed_br, side)
                    fold_onto_br = outgoing_branch(tt, start_sw, index-1, side)
                    if issubpath(encodings, fold_onto_br, signed_br)
                        if debug
                            println("Folding $(signed_br) onto $(fold_onto_br)...")
                        end
                        endsw = branch_endpoint(tt, fold_onto_br)
                        fold!(tt, -endsw, otherside(side), measure)
                        subtract_encoding!(encodings, signed_br, fold_onto_br)
                        if debug
                            println("TrainTrack gluing list: ", tt_gluinglist(tt))
                            # println("TrainTrack: ", tt)
                            println("Encodings: ")
                            printencoding(encodings)
                            println()
                        end
                        if length(encoding_of_branch(encodings, signed_br)) == 1                
                            deleteat!(branches_left, i) 
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
    @assert all(length(enc) == 1 for enc in encodings)

    switches_to_fix = Set(abs(branch_endpoint(tt, sg*br)) for br in branches_toconsider for sg in (-1,1))
    # Fixing switch orientations.
    for sw in switches_to_fix
        fix_switch_orientation!(tt, sw, encodings)
    end
end

function fix_switch_orientation!(tt::TrainTrack, sw::Int, encodings::Array{Array{ArcInPants, 1}, 1})
    # println(encodings)
    # println(outgoing_branches(tt, sw))
    # println(outgoing_branches(tt, -sw))
    @assert sw > 0
    for side in (LEFT, RIGHT)
        br = outgoing_branch(tt, sw, 1, side)
        arc = encoding_of_branch(encodings, br)[1]
        if ispantscurve(arc)
            if arc.direction == BACKWARD
                Donut.TrainTracks.Operations.reverseswitch!(tt, sw)
            end
            return
        end
    end
    @assert false
end

function peel_fold_elementarymove!(tt::TrainTrack, measure::Measure, pd::PantsDecomposition, update_encoding_fn::Function, encodings::Array{Array{ArcInPants, 1}, 1})
    update_encoding_fn(tt, pd, encodings)
    peel_to_remove_illegalturns!(tt, pd, encodings, measure) # TODO: supply the switches to consider as well.
    fold_peeledtt_back!(tt, measure, encodings) # TODO: supply the branches to consider.
end

function peel_fold_secondmove!(tt::TrainTrack, measure::Measure, pd::PantsDecomposition, curveindex::Int, encodings::Array{Array{ArcInPants, 1}, 1})
    peel_fold_elementarymove!(tt, measure, pd, (tt, pd, encodings)->update_encodings_after_secondmove!(tt, pd, curveindex, encodings), encodings)
end


function peel_fold_firstmove!(tt::TrainTrack, measure::Measure, pd::PantsDecomposition, curveindex::Int, encodings::Array{Array{ArcInPants, 1}, 1}, inverse=false)
    peel_fold_elementarymove!(tt, measure, pd, (tt, pd, encodings)->update_encodings_after_firstmove!(tt, pd, curveindex, encodings, inverse), encodings)
end
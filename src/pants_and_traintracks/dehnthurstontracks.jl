
module DehnThurstonTracks

export dehnthurstontrack, switch_turning, pantscurve_toswitch, pantscurve_to_branch, branches_at_pantend, findbranch, arc_in_pantsdecomposition

using Donut.Pants
using Donut.TrainTracks
using Donut.Constants
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.TrainTracks: BranchIterator
using Donut.PantsAndTrainTracks.Paths


doubledindex(x) = x > 0 ? 2*x-1 : -2*x


struct BranchData
    branchtype::PantsArcType
    pantindex::Int16
    bdyindex::BdyIndex
end



"""

The following conventions are used for constructing the branches:
    - bridges are oriented from boundary index i to i+1
    - self-connecting branches start on the right and come back on the left (i.e., they go around in counterclockwise order)
    - pants curves branches start at the positive end of the switch and end and the negative end of the switch.

The branches of the constructed train track are number from 1 to N for some N. The pants curve branches have the smallest numbers, then the bridges, finally the self-connecting branches.


"""
function dehnthurstontrack(pd::PantsDecomposition, pantstypes, turnings)
    ipc = innercurveindices(pd)

    if length(ipc) != length(turnings)
        error("The number of inner pants curves ($(length(ipc))) should equal the length of the turnings array ($(length(turnings))).")
    end
    if numpants(pd) != length(pantstypes)
        error("The number of pants ($(numpants(pd))) should equal the length of the pantstpyes array ($(length(pantstypes))).")
    end
    
    gluinglist = [Int[] for i in 1:2*length(ipc)]
    branchencodings = Path{ArcInPants}[]
    branchdata = BranchData[]

    # creating pants branches
    for i in eachindex(ipc)
        push!(gluinglist[2*i-1], i)
        push!(gluinglist[2*i], -i)
        push!(branchencodings, Path{ArcInPants}([PantsCurveArc(ipc[i])]))
        push!(branchdata, BranchData(PANTSCURVE, 0, BdyIndex(1)))
    end

    nextlabel = length(ipc) + 1
    for pant in 1:numpants(pd)
        typ = pantstypes[pant]

        curves = pantboundaries(pd, pant)

        switches = []
        for i in eachindex(curves)
            curve = curves[i]
            idx = findfirst(x->x==abs(curve), ipc)
            push!(switches, idx == nothing ? nothing : sign(curve)*idx)
        end
        bdyturnings = [sw==nothing ? nothing : turnings[abs(sw)] for sw in switches]

        addedbranches = BdyIndex[]
        # Adding bridges
        for idx1 in instances(BdyIndex)
            idx2 = nextindex(idx1)
            idx3 = previndex(idx1)
            if Int(idx1) == typ || switches[Int(idx2)] == nothing || switches[Int(idx3)] == nothing
                # If we have a self-connecting branch at idx1 or one of the endpoints of the bridge does not exists, then there is nothing to add.
                continue
            end

            if bdyturnings[Int(idx2)] == RIGHT
                x = gluinglist[doubledindex(switches[Int(idx2)])]
                splice!(x, length(x):length(x)-1, nextlabel)
            elseif bdyturnings[Int(idx2)] == LEFT
                x = gluinglist[doubledindex(-switches[Int(idx2)])]
                push!(x, nextlabel)
            else
                @assert false
            end

            if bdyturnings[Int(idx3)] == RIGHT
                x = gluinglist[doubledindex(switches[Int(idx3)])]
                pushfirst!(x, -nextlabel)
            elseif bdyturnings[Int(idx3)] == LEFT
                x = gluinglist[doubledindex(-switches[Int(idx3)])]
                splice!(x, 2:1, -nextlabel)
            else
                @assert false
            end
            nextlabel += 1
            push!(addedbranches, idx1)
            push!(branchdata, BranchData(BRIDGE, pant, idx1))
            push!(branchencodings, Path{ArcInPants}([BridgeArc(curves[Int(idx2)], curves[Int(idx3)])]))
        end


        if typ == 0
            # For type 0, there is no self-connecting branch.
            if length(addedbranches) != 3 && length(Set([abs(c) for c in curves])) == length(curves)
                error("A pair of pants can be type 0 only if all three bounding curves are inner pants curves.")
                # The purpose of the second condition is that it allows type 0 on the pants decomposition [1, -1, 2].
            end
            # No more branches to add for this pant.
            continue
        elseif !(typ in (1, 2, 3))
            error("Each pants type has to be 0, 1, 2 or 3.")
        end

        # Adding the self-connecting branch
        # Now typ = 1, 2, or 3
        bdyindex = BdyIndex(typ)
        curve = pantscurve_nextto_pant(pd, pant, bdyindex)
        if pant_nextto_pantscurve(pd, curve, LEFT) == pant_nextto_pantscurve(pd, curve, RIGHT)
            error("The resulting traintrack is not recurrent, because there is a self-connecting branch attached to a curve that has the same pair of pants on both sides.")
        end

        sw = switches[typ]
        if sw == nothing
            error("The self-connecting curves should be attached to inner pants curves.")
        end
        if bdyturnings[typ] == RIGHT
            x = gluinglist[doubledindex(sw)]
            splice!(x, length(x):length(x)-1, -nextlabel) 
            insertpos = previndex(bdyindex) in addedbranches ? -3 : -2
        else
            x = gluinglist[doubledindex(-sw)]
            push!(x, -nextlabel)
            insertpos = previndex(bdyindex) in addedbranches ? -2 : -1
        end
        splice!(x, length(x)+insertpos+1:length(x)+insertpos, nextlabel)
        nextlabel += 1
        push!(branchencodings, Path{ArcInPants}([SelfConnArc(curve, LEFT)]))
        push!(branchdata, BranchData(SELFCONN, pant, bdyindex))
    end
    tt = DecoratedTrainTrack(gluinglist)
    # println("constructor --------------------")
    # println(pd)
    # println(tt)
    # println(branchencodings)
    # println("-------------------------------")
    # println(gluinglist)
    # @assert length(branches(tt)) == numbranches
    tt, branchencodings, branchdata
end

function encoding_of_length1_branch(branchencodings::Vector{Path{ArcInPants}}, br::Integer)
    @assert length(branchencodings[abs(br)]) == 1
    # println("Br: ", br, " Encoding: ", br > 0 ? branchencodings[br][1] : reverse(branchencodings[-br][1]))
    return br > 0 ? branchencodings[br][1] : reverse(branchencodings[-br][1])
end


"""
Return the switch on the given pants curve. We use the convention that switch 1 is on the first inner pants curve, etc. 

The direction of the switch is assumed to be same as the direction of the pants curve. Therefore we sometimes need to fix the switch orientation after performing elementary moves.

# TODO: This method is now linear in the nunber of inner pants curves. It could be constant with more bookkeeping.
"""
function pantscurve_toswitch(pd::PantsDecomposition,
    tt::DecoratedTrainTrack, branchencodings::Vector{Path{ArcInPants}},
    pantscurveindex::Integer)
    # println(pd)
    # println(pantscurveindex)
    # return pantscurveindex

    # @assert sw > 0
    sw = pantscurveindex
    # println(sw)
    for side in (LEFT, RIGHT)
        br = extremal_branch(tt, sw, side)
        # println(br)
        arc = encoding_of_length1_branch(branchencodings, br)
        # println(arc)
        if arc isa PantsCurveArc
            if arc.curveindex == pantscurveindex
                return sw
            else
                return -sw
            end
        end
    end
    # println(pd)
    # println(tt)
    # println(branchencodings)
    # println(pantscurveindex)
    @assert false
end


function switch_turning(dttraintrack::DecoratedTrainTrack, sw::Integer, 
        branchencodings::Vector{Path{ArcInPants}})
    for side in (LEFT, RIGHT)
        br = extremal_branch(dttraintrack, sw, side)
        if encoding_of_length1_branch(branchencodings, br) isa PantsCurveArc
            return side
        end
    end
    # println(dttraintrack)
    # println(sw)
    # println(branchencodings)
    @assert false
end

function pantscurve_to_branch(pd::PantsDecomposition, pantscurveindex::Integer, 
        dttraintrack::DecoratedTrainTrack, branchencodings::Vector{Path{ArcInPants}})
    sw = pantscurve_toswitch(pd, dttraintrack, branchencodings, pantscurveindex)
    for side in (LEFT, RIGHT)
        br = extremal_branch(dttraintrack, sw, side)
        if encoding_of_length1_branch(branchencodings, br) isa PantsCurveArc
            return br
        end
    end
    @assert false
end

"""
The branches are always returned left to right. So for a self-connecting branch the beginning of the branch would come before the end of the branch.
"""
function branches_at_pantend(dttraintrack::DecoratedTrainTrack, pd::PantsDecomposition, 
        pantindex::Integer, bdyindex::BdyIndex, branchencodings::Vector{Path{ArcInPants}})
    pantscurveindex = pantscurve_nextto_pant(pd, pantindex, bdyindex)
    # println("Pantscurve: ", pantscurveindex)
    sw = pantscurve_toswitch(pd, dttraintrack, branchencodings, pantscurveindex)
    # println("Switch: ", sw)
    turning = switch_turning(dttraintrack, sw, branchencodings)
    # println("Turning: ", turning)
    if turning == LEFT
        sw = -sw
    end
    br1 = extremal_branch(dttraintrack, sw, turning)
    next_br = next_branch(dttraintrack, br1, otherside(turning))
    br2 = extremal_branch(dttraintrack, sw, otherside(turning))
    if turning == LEFT
        return BranchIterator(dttraintrack.tt, next_br, br2, turning)
    else
        return BranchIterator(dttraintrack.tt, br2, next_br, otherside(turning))
    end
end



function findbranch(dttraintrack::DecoratedTrainTrack, pd::PantsDecomposition, 
    pantindex::Integer, bdyindex::BdyIndex, branchtype::PantsArcType, 
    branchencodings::Vector{Path{ArcInPants}})
    # println("++++++++++++++++++++++++++++")
    # println(dttraintrack)
    # println(pd)
    # println(pantindex)
    # println(bdyindex)
    # println(branchtype)
    # println(branchencodings)
    # println("++++++++++++++++++++++++++++")
    if branchtype == SELFCONN
        # The self-connecting branch with the positive orientation starts on the left and ends at the right, so it is the first self-connecting branch we find scanning from left to right.
        for br in branches_at_pantend(dttraintrack, pd, pantindex, bdyindex, branchencodings)
            if encoding_of_length1_branch(branchencodings, br) isa SelfConnArc
                return br
            end
        end
    elseif branchtype == BRIDGE
        next_branches = branches_at_pantend(dttraintrack, pd, pantindex, 
            nextindex(bdyindex), branchencodings)
        # println("Next branches: ", next_branches)
        prev_branches = branches_at_pantend(dttraintrack, pd, pantindex, 
            previndex(bdyindex), branchencodings)
        # println("Prev branches: ", prev_branches)
        for br in next_branches
            # println("Branch candidate: ", br)
            if encoding_of_length1_branch(branchencodings, br) isa BridgeArc && -br in prev_branches
                return br
            end
        end
    elseif branchtype == PANTSCURVE
        curveindex = pantscurve_nextto_pant(pd, pantindex, bdyindex)
        return pantscurve_to_branch(pd, curveindex, dttraintrack, branchencodings)
    else
        @assert false
    end
    return nothing
end


"""
"""
function arc_in_pantsdecomposition(pd::PantsDecomposition, pantindex::Integer, 
    bdyindex::BdyIndex, is_reversed::Bool, arctype::PantsArcType)
    # println("arc_in_pantsdecomposition", pantindex, ", ", bdyindex, ", ", branchtype)
    if arctype == PANTSCURVE
        bdycurve = pantscurve_nextto_pant(pd, pantindex, bdyindex)
        return PantsCurveArc(is_reversed ? -bdycurve : bdycurve)
    elseif arctype == SELFCONN
        bdycurve = pantscurve_nextto_pant(pd, pantindex, bdyindex)
        return SelfConnArc(bdycurve, !is_reversed ? LEFT : RIGHT)
    elseif arctype == BRIDGE
        idx1 = nextindex(bdyindex)
        curve1 = pantscurve_nextto_pant(pd, pantindex, idx1)
        idx2 = previndex(bdyindex)
        curve2 = pantscurve_nextto_pant(pd, pantindex, idx2)
        newarc = BridgeArc(curve1, curve2)
        if is_reversed
            newarc = reverse(newarc)
        end
        return newarc
    else
        @assert false
    end
end






end





module DehnThurstonTracks

export dehnthurstontrack

using Donut.Pants
using Donut.TrainTracks
using Donut.Utils: nextindex, previndex, otherside
using Donut.Constants: LEFT, RIGHT

doubledindex(x) = x > 0 ? 2*x-1 : -2*x


struct BranchData
    branchtype::Int
    pantindex::Int
    bdyindex::Int
end

using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.PantsAndTrainTracks.ArcsInPants: PANTSCURVE, BRIDGE, SELFCONN


"""

The following conventions are used for constructing the branches:
    - bridges are oriented from boundary index i to i+1
    - self-connecting branches start on the right and come back on the left (i.e., they go around in counterclockwise order)
    - pants curves branches start at the positive end of the switch and end and the negative end of the switch.

The branches of the constructed train track are number from 1 to N for some N. The pants curve branches have the smallest numbers, then the bridges, finally the self-connecting branches.


"""
function dehnthurstontrack(pd::PantsDecomposition, pantstypes::Vector{Int}, turnings::Vector{Int})
    ipc = innercurveindices(pd)
    # TODO: handle one-sided pants curves
    @assert all(curve->istwosided_pantscurve(pd, curve), ipc)

    if length(ipc) != length(turnings)
        error("The number of inner pants curves ($(length(ipc))) should equal the length of the turnings array ($(length(turnings))).")
    end
    if numpants(pd) != length(pantstypes)
        error("The number of pants ($(numpants(pd))) should equal the length of the pantstpyes array ($(length(pantstypes))).")
    end
    
    gluinglist = [Int[] for i in 1:2*length(ipc)]
    twistedbranches = Int[]
    branchencodings = ArcInPants[]
    branchdata = BranchData[]

    # creating pants branches
    for i in eachindex(ipc)
        push!(gluinglist[2*i-1], i)
        push!(gluinglist[2*i], -i)
        push!(branchencodings, construct_pantscurvearc(ipc[i]))
        push!(branchdata, BranchData(PANTSCURVE, 0, 0))
    end


    nextlabel = length(ipc) + 1
    # numbranches = length(ipc) + 3*numpants(pd) - length(boundarycurveindices(pd))
    # selfconnindex = numbranches + 1 - count(x->x>0, pantstypes)
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
        isreversingend = [!ispantend_orientationpreserving(pd, pant, i) for i in 1:3]
        # We want the pant to be on the left side of the pants curves, from the perspective of the pants curves.
        for i in 1:3
            if isreversingend[i] && switches[i] != nothing
                switches[i] *= -1
            end
        end

        addedbranches = []
        # Adding bridges
        for idx1 in 1:3
            idx2 = nextindex(idx1, 3)
            idx3 = previndex(idx1, 3)
            if idx1 == typ || switches[idx2] == nothing || switches[idx3] == nothing
                # If we have a self-connecting branch at idx1 or one of the endpoints of the bridge does not exists, then there is nothing to add.
                continue
            end

            if bdyturnings[idx2] == RIGHT
                x = gluinglist[doubledindex(switches[idx2])]
                splice!(x, length(x):length(x)-1, nextlabel)
            elseif bdyturnings[idx2] == LEFT
                x = gluinglist[doubledindex(-switches[idx2])]
                push!(x, nextlabel)
            else
                @assert false
            end

            if bdyturnings[idx3] == RIGHT
                x = gluinglist[doubledindex(switches[idx3])]
                pushfirst!(x, -nextlabel)
            elseif bdyturnings[idx3] == LEFT
                x = gluinglist[doubledindex(-switches[idx3])]
                splice!(x, 2:1, -nextlabel)
            else
                @assert false
            end
            if isreversingend[idx2] != isreversingend[idx3]
                push!(twistedbranches, nextlabel)
            end
            nextlabel += 1
            push!(addedbranches, idx1)
            push!(branchdata, BranchData(BRIDGE, pant, idx1))
            v1 = !isreversingend[idx2] ? curves[idx2] : curves[idx2]
            v2 = !isreversingend[idx3] ? curves[idx3] : curves[idx3]
            push!(branchencodings, construct_bridge(v1, v2))
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
        curve = pantscurve_nextto_pant(pd, pant, typ)
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
            insertpos = previndex(typ, 3) in addedbranches ? -3 : -2
        else
            x = gluinglist[doubledindex(-sw)]
            push!(x, -nextlabel)
            insertpos = previndex(typ, 3) in addedbranches ? -2 : -1
        end
        splice!(x, length(x)+insertpos+1:length(x)+insertpos, nextlabel)
        nextlabel += 1
        c = ispantend_orientationpreserving(pd, pant, typ) ? curve : -curve
        push!(branchencodings, construct_selfconnarc(c))
        push!(branchdata, BranchData(SELFCONN, pant, typ))
    end
    tt = TrainTrack(gluinglist, twistedbranches)
    # @assert length(branches(tt)) == numbranches
    tt, branchencodings, branchdata
end



"""
Return the switch on the given pants curve. We use the convention that switch 1 is on the first inner pants curve, etc. 

The direction of the switch is assumed to be same as the direction of the pants curve. Therefore we sometimes need to fix the switch orientation after performing elementary moves.

# TODO: This method is now linear in the nunber of inner pants curves. It could be constant with more bookkeeping.
"""
function pantscurve_toswitch(pd::PantsDecomposition, pantscurveindex::Int) 
    sw = findfirst(x->x==abs(pantscurveindex), innercurveindices(pd))
    return sign(pantscurveindex) * sw
end


function switch_turning(dttraintrack::TrainTrack, sw::Int, branchencodings::Vector{ArcInPants})
    for side in (LEFT, RIGHT)
        br = outgoing_branch(dttraintrack, sw, 1, side)
        if ispantscurve(branchencodings[abs(br)])
            return side
        end
    end
    @assert false
end

function pantscurve_to_branch(pd::PantsDecomposition, pantscurveindex::Int, dttraintrack::TrainTrack, branchencodings::Vector{ArcInPants})
    sw = pantscurve_toswitch(pd, pantscurveindex)
    for side in (LEFT, RIGHT)
        br = outgoing_branch(dttraintrack, sw, 1, side)
        if ispantscurvearc(branchencodings[abs(br)])
            return br
        end
    end
    @assert false
end

"""
The branches are always returned left to right. So for a self-connecting branch the beginning of the branch would come before the end of the branch.
"""
function branches_at_pantend(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchencodings::Vector{ArcInPants})
    pantscurveindex = pantscurve_nextto_pant(pd, pantindex, bdyindex)
    sw = pantscurve_toswitch(pd, pantscurveindex)
    turning = switch_turning(dttraintrack, sw, branchencodings)
    if turning == LEFT
        sw = -sw
    end
    if !ispantend_orientationpreserving(pd, pantindex, bdyindex)
        sw = -sw
    end
    brs = outgoing_branches(dttraintrack, sw, turning)
    branches = brs[2:length(brs)]
    if (turning == LEFT) == ispantend_orientationpreserving(pd, pantindex, bdyindex)
        return branches
    else
        return reverse(branches)
    end
end



function findbranch(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchtype::Int, branchencodings::Vector{ArcInPants})
    if branchtype == SELFCONN
        # The self-connecting branch with the positive orientation starts on the left and ends at the right, so it is the first self-connecting branch we find scanning from left to right.
        for br in branches_at_pantend(dttraintrack, pd, pantindex, bdyindex, branchencodings)
            if isselfconnecting(branchencodings[abs(br)])
                return br
            end
        end
    elseif branchtype == BRIDGE
        next_branches = branches_at_pantend(dttraintrack, pd, pantindex, nextindex(bdyindex, 3), branchencodings)
        prev_branches = branches_at_pantend(dttraintrack, pd, pantindex, previndex(bdyindex, 3), branchencodings)
        for br in next_branches
            if isbridge(branchencodings[abs(br)]) && -br in prev_branches
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
bdyindex can be -3, -2, -1, 1, 2, 3. If it is negative, the constructed arc is reversed.
"""
function arc_in_pantsdecomposition(pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchtype::Int)
    # println("arc_in_pantsdecomposition", pantindex, ", ", bdyindex, ", ", branchtype)
    if branchtype == PANTSCURVE
        bdycurve = pantscurve_nextto_pant(pd, pantindex, abs(bdyindex))
        return pantscurvearc(abs(bdycurve), bdycurve * bdyindex > 0 ? FORWARD : BACKWARD)
    elseif branchtype == SELFCONN
        bdycurve, side = pantend_to_pantscurveside(pd, pantindex, abs(bdyindex))
        if bdycurve < 0
            side = otherside(side)
        end
        return selfconnarc(abs(bdycurve), side, bdyindex > 0 ? LEFT : RIGHT)
    elseif branchtype == BRIDGE
        idx1 = nextindex(abs(bdyindex), 3)
        curve1, side1 = pantend_to_pantscurveside(pd, pantindex, idx1)
        if curve1 < 0
            side1 = otherside(side1)
        end

        idx2 = previndex(abs(bdyindex), 3)
        curve2, side2 = pantend_to_pantscurveside(pd, pantindex, idx2)
        if curve2 < 0
            side2 = otherside(side2)
        end
        newarc = ArcInPants(abs(curve1), side1, abs(curve2), side2)
        if bdyindex < 0
            newarc = reversed(newarc)
        end
        return newarc
    else
        @assert false
    end
end


# ---------------------------------------------
# Branch encoding construction
# ---------------------------------------------


# function encoding(branchtype::Int, startpantscurve::Int)
#     if branchtype == PANTSCURVE
#         return 
#     elseif
# end

# function branchencodings(dttraintrack::TrainTrack, turnings::Array{Int, 1}, branchdata::Array{BranchData})
#     encodings = ArcInPants[]

#     for br in branches(dttraintrack)  # actually 1:length(branches)
#         startvertex = branch_endpoint(dttraintrack, -br)
#         endvertex = branch_endpoint(dttraintrack, br)
#         function gate(vertex)
#             g = turnings[abs(vertex)]
#             return vertex > 0 ? otherside(g) : g
#         end
#         data = branchdata[br]
#         if data.branchtype == PANTSCURVE
#             push!(encodings, pantscurvearc(abs(startvertex), FORWARD))
#         elseif data.branchtype == BRIDGE
#             startgate = gate(startvertex)
#             endgate = gate(endvertex)
#             push!(encodings, ArcInPants(abs(startvertex), startgate, abs(endvertex), endgate))
#         elseif data.branchtype == SELFCONN
#             startgate = gate(startvertex)
#             push!(encodings, selfconnarc(abs(startvertex), startgate, RIGHT))
#         else
#             @assert false
#         end
#     end
#     [[enc] for enc in encodings]
# end






end




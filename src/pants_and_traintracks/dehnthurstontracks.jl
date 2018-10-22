
export dehnthurstontrack, branchencodings

using Donut.Pants
using Donut.TrainTracks
using Donut.Utils: nextindex, previndex, otherside
using Donut.Constants: LEFT, RIGHT
using Donut.Pants.DTCoordinates
using Donut.TrainTracks.Measures

doubledindex(x) = x > 0 ? 2*x-1 : -2*x

const PANTSCURVE = 1
const SELFCONN = 2
const BRIDGE = 3

struct BranchData
    branchtype::Int
    pantindex::Int
    bdyindex::Int
end

"""

The following conventions are used for constructing the branches:
    - bridges are oriented from boundary index i to i+1
    - self-connecting branches start on the right and come back on the left (i.e., they go around in counterclockwise order)
    - pants curves branches start at the positive end of the switch and end and the negative end of the switch.

The branches of the constructed train track are number from 1 to N for some N. The pants curve branches have the smallest numbers, then the bridges, finally the self-connecting branches.


"""
function dehnthurstontrack(pd::PantsDecomposition, pantstypes::Array{Int,1}, turnings::Array{Int, 1})
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
    branchdata = BranchData[]

    # creating pants branches
    for i in eachindex(ipc)
        push!(gluinglist[2*i-1], i)
        push!(gluinglist[2*i], -i)
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
        push!(branchdata, BranchData(SELFCONN, pant, typ))
    end
    tt = TrainTrack(gluinglist, twistedbranches)
    # @assert length(branches(tt)) == numbranches
    tt, branchdata
end



function branchencodings(dttraintrack::TrainTrack, turnings::Array{Int, 1}, branchdata::Array{BranchData})
    encodings = ArcInPants[]

    for br in branches(dttraintrack)  # actually 1:length(branches)
        startvertex = branch_endpoint(dttraintrack, -br)
        endvertex = branch_endpoint(dttraintrack, br)
        function gate(vertex)
            g = turnings[abs(vertex)]
            return vertex > 0 ? otherside(g) : g
        end
        data = branchdata[br]
        if data.branchtype == PANTSCURVE
            push!(encodings, pantscurvearc(abs(startvertex), FORWARD))
        elseif data.branchtype == BRIDGE
            startgate = gate(startvertex)
            endgate = gate(endvertex)
            push!(encodings, ArcInPants(abs(startvertex), startgate, abs(endvertex), endgate))
        elseif data.branchtype == SELFCONN
            startgate = gate(startvertex)
            push!(encodings, selfconnarc(abs(startvertex), startgate, RIGHT))
        else
            @assert false
        end
    end
    encodings
end


function selfconn_and_bridge_measures(ints1::Integer, ints2::Integer, ints3::Integer)
    ints = [ints1, ints2, ints3]
    selfconn = [max(ints[i] - ints[nextindex(i, 3)] - ints[previndex(i, 3)], 0) for i in 1:3]
    if any(x % 2 == 1 for x in selfconn)
        error("The specified coordinates do not result in an integral lamination: an odd number is divided by 2.")
    end
    selfconn = [div(x, 2) for x in selfconn]  

    # take out the self-connecting strands, now the triangle ineq. is
    # satisfied
    adjusted_measures = [ints[i] - 2*selfconn[i] for i in 1:3]
    bridges = [max(adjusted_measures[previndex(i, 3)] + adjusted_measures[nextindex(i, 3)] - adjusted_measures[i], 0) for i in 1:3]
    if any(x % 2 == 1 for x in bridges)
        error("The specified coordinates do not result in an integral lamination: an odd number is divided by 2.")
    end
    bridges = [div(x, 2) for x in bridges]  
    return selfconn, bridges
end

"""
From the Dehn-Thurston coordinates, creates an array whose i'th element is the intersection number of the i'th pants curve. (Boundary pants curves are also included in this array.)
"""
function allcurve_intersections(pd::PantsDecomposition, intersection_numbers::Array{Real})
    T = typeof(intersection_numbers[1])
    curves = curveindices(pd)
    len = maximum(curves)
    allintersections = fill(T(0), len)
    innerindices = innercurveindices(pd)
    if length(innerindices) != length(intersection_numbers)
        error("Mismatch between number of inner pants curves ($(length(innerindices))) and the number of Dehn-Thurston coordinates ($(length(intersection_numbers))).")
    end
    for i in eachindex(innerindices)
        allintersections[innerindices[i]] = intersection_numbers[i]
    end
    return allintersections
end


function determine_panttype(pd::PantsDecomposition, bdycurves, selfconn, bridges)
    # println(bdycurves)
    # println(selfconn)
    # println(bridges)
    # if at all possible, we include a self-connecting curve
    # first we check if there is a positive self-connecting measure in
    # which case the choice is obvious
    for i in 1:3
        if selfconn[i] > 0
            return i
        end
    end

    # If the value is self_conn_idx is still not determined, we see if the pairing measures allow including a self-connecting branch
    for i in 1:3
        curve = bdycurves[i]
        # making sure the opposite pair has zero measure
        if bridges[i] == 0 && isinner_pantscurve(pd, curve) && pant_nextto_pantscurve(pd, curve, LEFT) != pant_nextto_pantscurve(pd, curve, RIGHT) 
            # if the type is first move, then the self-connecting
            # branch would make the train track not recurrent
            return i
        end
    end
    return 0
end


function determine_measure(dttraintrack::TrainTrack, twisting_numbers, selfconn_and_bridge_measures, branchdata::Array{BranchData})
    T = typeof(twisting_numbers[1])
    measure = T[]
    for br in eachindex(twisting_numbers)
        # println("Pantscurve")
        push!(measure, abs(twisting_numbers[br]))
        @assert branchdata[br].branchtype == PANTSCURVE
    end
    for br in length(twisting_numbers)+1:length(branchdata)
        data = branchdata[br]
        if data.branchtype == BRIDGE
            # println("Bridge")

            push!(measure, selfconn_and_bridge_measures[data.pantindex][2][data.bdyindex])
        elseif data.branchtype == SELFCONN
            # println("Selfconn")

            push!(measure, selfconn_and_bridge_measures[data.pantindex][1][data.bdyindex])
        else
            @assert false
        end
    end
    Measure{T}(dttraintrack, measure)
end


function dehnthurstontrack(pd::PantsDecomposition, dtcoords::DehnThurstonCoordinates)

    allintersections = allcurve_intersections(pd, dtcoords.intersection_numbers)
 
    sb_measures = [selfconn_and_bridge_measures([allintersections[abs(c)] for c in pantboundaries(pd, pant)]...) for pant in pants(pd)]
    
    pantstypes = [determine_panttype(pd, pantboundaries(pd, pant), sb_measures[pant]...) for pant in pants(pd)]

    turnings = [twist < 0 ? LEFT : RIGHT for twist in dtcoords.twisting_numbers]

    tt, branchdata = dehnthurstontrack(pd, pantstypes, turnings)

    measure = determine_measure(tt, dtcoords.twisting_numbers, sb_measures, branchdata)
    encodings = branchencodings(tt, turnings, branchdata)

    tt, measure, encodings
end


"""
Return the switch on the given pants curve. We use the convention that switch 1 is on the first inner pants curve, etc.

# TODO: This method is now linear in the nunber of inner pants curves. It could be constant with more bookkeeping.
"""
function pantscurve_toswitch(pd::PantsDecomposition, pantscurveindex::Int) 
    sw = findfirst(x->x==abs(pantscurveindex), innercurveindices(pd))
    return sign(pantscurveindex) * sw
end

function switch_turning(dttraintrack::TrainTrack, sw::Int, branchencodings::Array{ArcInPants})
    for side in (LEFT, RIGHT)
        br = outgoing_branch(dttraintrack, sw, 1, side)
        if ispantscurve(branchencodings[abs(br)])
            return side
        end
    end
    @assert false
end

function pantscurve_to_branch(pd::PantsDecomposition, pantscurveindex::Int, dttraintrack::TrainTrack, branchencodings::Array{ArcInPants})
    sw = pantscurve_toswitch(pd, pantscurveindex)
    for side in (LEFT, RIGHT)
        br = outgoing_branch(dttraintrack, sw, 1, side)
        if ispantscurve(branchencodings[abs(br)])
            return br
        end
    end
    @assert false
end

function branches_at_pantend(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchencodings::Array{ArcInPants})
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
    brs[2:length(brs)]
end

function findbranch(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchtype::Int, branchencodings::Array{ArcInPants})
    if branchtype == SELFCONN
        fn = isselfconnecting
        idx = bdyindex
    elseif branchtype == BRIDGE
        fn = isbridge
        idx = nextindex(bdyindex, 3)
    else
        @assert false
    end
    for br in branches_at_pantend(dttraintrack, pd, pantindex, idx, branchencodings)
        if br > 0 && fn(branchencodings[br])
            return br
        end
    end
    return nothing
end



function encodings_after_halftwist(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchencodings::Array{ArcInPants})
    long_encodings = [[enc] for enc in branchencodings]

    # pantscurveindex = pantscurve_nextto_pant(pd, pantindex, bdyindex)
    # pantsbr = pantscurve_to_branch(pd, pantscurveindex, dttraintrack, branchencodings)

    idx1, idx2, idx3 = bdyindex, nextindex(bdyindex, 3), previndex(bdyindex, 3)
    replacements = [
        [],
        # SELFCONN
        [
            [(PANTSCURVE, -idx1), (SELFCONN, -idx1)], # idx1
            [(SELFCONN, -idx3), (PANTSCURVE, -idx3)], # idx2
            [(SELFCONN, idx2), (PANTSCURVE, -idx2)]  # idx3
        ], 
        # BRIDGES
        [
            [(PANTSCURVE, idx3), (BRIDGE, -idx1)], # idx1
            [(PANTSCURVE, idx2), (BRIDGE, -idx3), (PANTSCURVE, idx1)], # idx2
            [(BRIDGE, -idx2)]  # idx3
        ]
    ]
    for branchtype in (SELFCONN, BRIDGE)
        for i in 1:3
            reps = replacements[branchtype][i]
            idx = (idx1, idx2, idx3)[i]
            br = findbranch(dttraintrack, pd, pantindex, idx, branchtype, branchencodings)
            if br != nothing
                long_encodings[br] = [arc_in_pantsdecomposition(pd, pantindex, idxx, typ) for (typ, idxx) in reps]
            end
        end
    end

    return long_encodings
end

# function pantend_togate(pd::PantsDecomposition, pantindex::Int, bdyindex::Int)
#     ispantend_orientationpreserving(pd, pantindex, bdyindex) == (pantscurve_nextto_pant(pd, pantindex, bdyindex) > 0) ? LEFT : RIGHT
# end

"""
bdyindex can be -3, -2, -1, 1, 2, 3. If it is negative, the constructed arc is reversed.
"""
function arc_in_pantsdecomposition(pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchtype::Int)
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
        curve1, side1 = pantend_to_pantscurveside(pd, pantindex, abs(idx1))
        if curve1 < 0
            side1 = otherside(side1)
        end
        # println(v1)
        # println(g1)

        idx2 = previndex(abs(bdyindex), 3)
        curve2, side2 = pantend_to_pantscurveside(pd, pantindex, abs(idx2))
        if curve2 < 0
            side2 = otherside(side2)
        end
        # println(v2)
        # println(g2)
        newarc = ArcInPants(abs(curve1), side1, abs(curve2), side2)
        if bdyindex < 0
            newarc = reversed(newarc)
        end
        return newarc
    else
        @assert false
    end
end


# module DehnThurstonTracks

export dehnthurstontrack, branchencodings

using Donut.Pants
using Donut.TrainTracks
using Donut.Utils: nextindex, previndex, otherside
using Donut.Constants: LEFT, RIGHT

doubledindex(x) = x > 0 ? 2*x-1 : -2*x


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

    # creating pants branches
    for i in eachindex(ipc)
        push!(gluinglist[2*i-1], i)
        push!(gluinglist[2*i], -i)
    end


    bridgeindex = length(ipc) + 1
    numbranches = length(ipc) + 3*numpants(pd) - length(boundarycurveindices(pd))
    selfconnindex = numbranches + 1 - count(x->x>0, pantstypes)
    for pant in 1:numpants(pd)
        typ = pantstypes[pant]

        curves = [pantscurve_nextto_pant(pd, pant, i) for i in 1:3]

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
            if typ > 0 && idx1 == nextindex(typ, 3)
                # It is not type 0 (there is a self-connecting branch) and that self-connecting branch blocks the bridge we are about to add.
                continue
            end

            if switches[idx1] == nothing || switches[idx2] == nothing 
                # At least one of the curves is a boundary curve. In this case, there is nothing to add.
                continue
                # error("Cannot add a bridge branch if one of the pants curves is a boundary pants curve.")
            end

            if bdyturnings[idx1] == RIGHT
                x = gluinglist[doubledindex(switches[idx1])]
                splice!(x, length(x):length(x)-1, bridgeindex)
            elseif bdyturnings[idx1] == LEFT
                x = gluinglist[doubledindex(-switches[idx1])]
                push!(x, bridgeindex)
            else
                @assert false
            end

            if bdyturnings[idx2] == RIGHT
                x = gluinglist[doubledindex(switches[idx2])]
                pushfirst!(x, -bridgeindex)
            elseif bdyturnings[idx2] == LEFT
                x = gluinglist[doubledindex(-switches[idx2])]
                splice!(x, 2:1, -bridgeindex)
            else
                @assert false
            end
            if isreversingend[idx1] != isreversingend[idx2]
                push!(twistedbranches, bridgeindex)
            end
            bridgeindex += 1
            push!(addedbranches, idx1)
        end

        if typ == 0
            # For type 0, there is no self-connecting branch.
            if length(addedbranches) != 3
                error("A pair of pants can be type only if all three bounding curves are inner pants curves.")
            end
            # No more branches to add for this pant.
            continue
        elseif !(typ in (1, 2, 3))
            error("Each pants type has to be 0, 1, 2 or 3.")
        end

        # Adding the self-connecting branch
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
            splice!(x, length(x):length(x)-1, -selfconnindex) 
            insertpos = previndex(typ, 3) in addedbranches ? -3 : -2
        else
            x = gluinglist[doubledindex(-sw)]
            push!(x, -selfconnindex)
            insertpos = previndex(typ, 3) in addedbranches ? -2 : -1
        end
        splice!(x, length(x)+insertpos+1:length(x)+insertpos, selfconnindex)
        selfconnindex += 1
    end
    tt = TrainTrack(gluinglist, twistedbranches)
    @assert length(branches(tt)) == numbranches
    tt
end



function branchencodings(dttraintrack::TrainTrack, turnings::Array{Int, 1}, numselfconnects::Int)
    encodings = ArcInPants[]
    numinnercurves = length(turnings)
    for br in branches(dttraintrack)
        startvertex = branch_endpoint(dttraintrack, -br)
        endvertex = branch_endpoint(dttraintrack, br)
        function gate(vertex)
            g = turnings[abs(vertex)]
            return vertex > 0 ? otherside(g) : g
        end
        if br <= numinnercurves
            # Pants curve branch
            push!(encodings, pantscurvearc(abs(startvertex), FORWARD))
        elseif br <= length(branches(dttraintrack)) - numselfconnects
            # bridge
            startgate = gate(startvertex)
            endgate = gate(endvertex)
            push!(encodings, ArcInPants(abs(startvertex), startgate, abs(endvertex), endgate))
        else
            # self-connecting
            startgate = gate(startvertex)
            push!(encodings, selfconnarc(abs(startvertex), startgate, RIGHT))
        end
    end
    encodings
end

# end

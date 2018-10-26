
export update_encodings_after_halftwist!, update_encodings_after_dehntwist!, update_encodings_after_firstmove!, update_encodings_after_secondmove!


using Donut.Pants.ElementaryMoves

function replacement_rules_twist(twistdirection::Int=RIGHT)
    # idx1, idx2, idx3 = bdyindex, nextindex(bdyindex, 3), previndex(bdyindex, 3)
    sg = twistdirection == LEFT ? 1 : -1
    return [
        ((BRIDGE, 3), [(PANTSCURVE, -sg), (BRIDGE, 3)]),
        ((BRIDGE, 2), [(BRIDGE, 2), (PANTSCURVE, -sg)]),
        ((SELFCONN, 1), [(PANTSCURVE, -sg), (SELFCONN, 1), (PANTSCURVE, sg)])
    ]
end

const REPLACEMENT_RULES_HALFTWIST = [
    ((SELFCONN, 1), [(PANTSCURVE, -1), (SELFCONN, -1)]),
    ((SELFCONN, 2), [(SELFCONN, -3), (PANTSCURVE, -3)]),
    ((SELFCONN, 3), [(SELFCONN, 2), (PANTSCURVE, -2)]),
    ((BRIDGE, 1), [(PANTSCURVE, 3), (BRIDGE, -1)]),
    ((BRIDGE, 2), [(PANTSCURVE, 2), (BRIDGE, -3), (PANTSCURVE, 1)]),
    ((BRIDGE, 3), [(BRIDGE, -2)])
]

const REPLACEMENT_RULES_FIRSTMOVE = [
    ((BRIDGE, 1), [(PANTSCURVE, 2)]),
    ((BRIDGE, 2), [(BRIDGE, -3)]),
    ((BRIDGE, 3), [(BRIDGE, 3), (PANTSCURVE, -2)]),
    ((PANTSCURVE, 2), [(BRIDGE, -1)]),
    ((SELFCONN, 1), [(BRIDGE, 3), (BRIDGE, 2), (PANTSCURVE, -1)])
]

const REPLACEMENT_RULES_SECONDMOVE_UPPER = [
    ((BRIDGE, 1), [(BRIDGE, 2, RIGHT), (BRIDGE, 3, LEFT)]),
    ((BRIDGE, 2), [(BRIDGE, -3, LEFT)]),
    ((BRIDGE, 3), [(BRIDGE, -2, RIGHT)]),
    ((SELFCONN, 1), [(PANTSCURVE, -1, RIGHT), (SELFCONN, -1, RIGHT)]),
    ((SELFCONN, 2), [(BRIDGE, 2, RIGHT), (SELFCONN, 1, LEFT), (BRIDGE, -2, RIGHT)]),
    ((SELFCONN, 3), [(BRIDGE, -3, LEFT), (SELFCONN, 1, RIGHT), (PANTSCURVE, 1, RIGHT), (BRIDGE, 3, LEFT), (PANTSCURVE, -2, LEFT)]),
    ((PANTSCURVE, 1), [(SELFCONN, 1, RIGHT), (PANTSCURVE, 1, RIGHT), (SELFCONN, -1, LEFT)])
]

const REPLACEMENT_RULES_SECONDMOVE_LOWER = [(a, [(triple[1], triple[2], otherside(triple[3])) for triple in b]) for (a, b) in REPLACEMENT_RULES_SECONDMOVE_UPPER]


function compile_oldbranch(dttraintrack::TrainTrack, pd::PantsDecomposition, branchencodings::Array{Array{ArcInPants, 1}, 1}, branchtype::Int, bdyindex::Int, pantindex::Int, marking_bdyindex::Int)
    indices = marking_bdyindex, nextindex(marking_bdyindex, 3), previndex(marking_bdyindex, 3)
    findbranch(dttraintrack, pd, pantindex, indices[bdyindex], branchtype, branchencodings)
    # if x!= nothing && abs(x) == 9
    #     println("------")
    #     println(pantindex)
    #     println(bdyindex)
    #     println(indices[bdyindex])
    #     println(branchtype)
    # end
    # x
end

"""
Compile the raw replacement rules so that the first part of each rule is replaced by the label of the branch. If that branch does not exist in the train track, the rule is ignored.
"""
function compile_oldbranches(dttraintrack::TrainTrack, pd::PantsDecomposition, branchencodings::Array{Array{ArcInPants, 1}, 1}, replacement_rules, pantindex::Int, marking_bdyindex::Int)
    ret = []
    for rule in replacement_rules
        br = compile_oldbranch(dttraintrack, pd, branchencodings, rule[1][1], rule[1][2], pantindex, marking_bdyindex)
        if br != nothing
            push!(ret, (br, rule[2]))
        end
    end
    ret
end

function compile_newbranch(pd_aftermove::PantsDecomposition, branchtype::Int, bdyindex::Int, pantindex::Int, marking_bdyindex::Int)
    indices = (marking_bdyindex, nextindex(marking_bdyindex, 3), previndex(marking_bdyindex, 3))
    arc_in_pantsdecomposition(pd_aftermove, pantindex, sign(bdyindex)*indices[abs(bdyindex)], branchtype)
end

function compile_newbranch_twopants(pd_aftermove::PantsDecomposition, branchtype::Int, bdyindex::Int, side::Int, leftpantindex::Int, rightpantindex::Int)
    # println(pd_aftermove)
    arc_in_pantsdecomposition(pd_aftermove, side == LEFT ? leftpantindex : rightpantindex, bdyindex, branchtype)
end

function compile_newbranches(replacement_rules, compile_fn::Function)
    [(br, [compile_fn(item) for item in newdata]) for (br, newdata) in replacement_rules]
end

function update_branchencodings!(branchencodings::Array{Array{ArcInPants, 1}, 1}, compiledrules::Array{Tuple{Int, Array{ArcInPants,1}},1})

    for (br, newencoding) in compiledrules
        # TODO: br can be negative.
        if br > 0
            branchencodings[br] = newencoding
        else
            branchencodings[-br] = reversedpath(newencoding)
        end
    end
end

# TODO: implement an inverse half twist. For now a half-twist plus and inverse Dehn twist does the job.
function update_encodings_after_halftwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchencodings::Array{Array{ArcInPants, 1}, 1})
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_HALFTWIST, pantindex, bdyindex)

    apply_halftwist!(pd, pantindex, bdyindex)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_dehntwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, direction::Int, branchencodings::Array{Array{ArcInPants, 1}, 1})
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, replacement_rules_twist(direction), pantindex, bdyindex)

    apply_dehntwist!(pd, pantindex, bdyindex, direction)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))


    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_firstmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, curveindex::Int, branchencodings::Array{Array{ArcInPants, 1}, 1})

    pantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
    bdyindex = findfirst(i->abs(pantscurve_nextto_pant(pd, pantindex, i)) != abs(curveindex), 1:3)

    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_FIRSTMOVE, pantindex, bdyindex)

    apply_firstmove!(pd, curveindex)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_secondmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, curveindex::Int, branchencodings::Array{Array{ArcInPants, 1}, 1})
    upperpantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
    upperbdyindex = bdyindex_nextto_pantscurve(pd, curveindex, LEFT)
    lowerpantindex = pant_nextto_pantscurve(pd, curveindex, RIGHT)
    lowerbdyindex = bdyindex_nextto_pantscurve(pd, curveindex, RIGHT)
    
    # println(upperpantindex)
    # println(upperbdyindex)
    # println(lowerpantindex)
    # println(lowerbdyindex)
    # lowerrules = REPLACEMENT_RULES_SECONDMOVE
    # swapping lefts to rights

    compiledrules1 = [
        compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_SECONDMOVE_UPPER, upperpantindex, upperbdyindex); 
        compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_SECONDMOVE_LOWER[1:length(REPLACEMENT_RULES_SECONDMOVE_LOWER)-1], lowerpantindex, lowerbdyindex)
    ]

    apply_secondmove!(pd, curveindex)
    
    # println("CP1: ", compiledrules1)
    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch_twopants(pd, newdata..., upperpantindex, lowerpantindex))
    # println("CP2: ", compiledrules2)

    update_branchencodings!(branchencodings, compiledrules2)
end



# TODO: Change the encodings back to Array{ArcInPants} whereever possible and when the encodings are updated, store the updates in a separate Array{Array{ArcInPants}} array. (Only those entries would be nonempty when changes are needed.)

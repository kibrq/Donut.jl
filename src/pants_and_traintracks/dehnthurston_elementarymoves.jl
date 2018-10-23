
export encodings_after_halftwist!, encodings_after_dehntwist!, encodings_after_firstmove!, encodings_after_secondmove!


using Donut.Pants.ElementaryMoves

function replacement_rules_twist(twistdirection::Int=RIGHT)
    # idx1, idx2, idx3 = bdyindex, nextindex(bdyindex, 3), previndex(bdyindex, 3)
    sg = twistdirection == LEFT ? 1 : -1
    return [
        ((BRIDGE, 3), [(PANTSCURVE, -sg), (BRIDGE, 3)]),
        ((BRIDGE, 2), [(PANTSCURVE, -sg), (BRIDGE, 2)]),
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

const REPLACEMENT_RULES_SECONDMOVE = [ # one of the two pants
    ((BRIDGE, 1), [(BRIDGE, 2, RIGHT), (BRIDGE, 3, LEFT)]),
    ((BRIDGE, 2), [(BRIDGE, -3, LEFT)]),
    ((BRIDGE, 3), [(BRIDGE, -2, RIGHT)]),
    ((SELFCONN, 1), [(PANTSCURVE, -1, RIGHT), (SELFCONN, -1, RIGHT)]),
    ((SELFCONN, 2), [(BRIDGE, 2, RIGHT), (SELFCONN, 1, LEFT), (BRIDGE, -2, RIGHT)]),
    ((SELFCONN, 3), [(BRIDGE, -3, LEFT), (SELFCONN, 1, RIGHT), (PANTSCURVE, 1, RIGHT), (BRIDGE, 3, LEFT), (PANTSCURVE, -2, LEFT)]),
    ((PANTSCURVE, 1), [(SELFCONN, 1, RIGHT), (PANTSCURVE, 1, RIGHT), (SELFCONN, -1, LEFT)])
]


function compile_oldbranch(dttraintrack::TrainTrack, pd::PantsDecomposition, branchencodings::Array{ArcInPants}, branchtype::Int, bdyindex::Int, pantindex::Int, marking_bdyindex::Int)
    indices = marking_bdyindex, nextindex(marking_bdyindex, 3), previndex(marking_bdyindex, 3)
    findbranch(dttraintrack, pd, pantindex, indices[bdyindex], branchtype, branchencodings)
end

"""
Compile the raw replacement rules so that the first part of each rule is replaced by the label of the branch. If that branch does not exist in the train track, the rule is ignored.
"""
function compile_oldbranches(dttraintrack::TrainTrack, pd::PantsDecomposition, branchencodings::Array{ArcInPants}, replacement_rules, pantindex::Int, marking_bdyindex::Int)
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
    arc_in_pantsdecomposition(pd_aftermove, side == LEFT ? leftpantindex : rightpantindex, bdyindex, branchtype )
end

function compile_newbranches(replacement_rules, compile_fn::Function)
    [(br, [compile_fn(item) for item in newdata]) for (br, newdata) in replacement_rules]
end

function generate_new_branchencodings(branchencodings::Array{ArcInPants}, compiledrules::Array{Tuple{Int, Array{ArcInPants,1}},1})

    long_encodings = [[enc] for enc in branchencodings]

    for (br, newencoding) in compiledrules
        # TODO: br can be negative.
        long_encodings[br] = newencoding
    end
    long_encodings
end

# TODO: implement an inverse half twist. For now a half-twist plus and inverse Dehn twist does the job.
function encodings_after_halftwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, branchencodings::Array{ArcInPants})
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_HALFTWIST, pantindex, bdyindex)

    apply_halftwist!(pd, pantindex, bdyindex)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    generate_new_branchencodings(branchencodings, compiledrules2)
end

function encodings_after_dehntwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, pantindex::Int, bdyindex::Int, direction::Int, branchencodings::Array{ArcInPants})
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, replacement_rules_twist(direction), pantindex, bdyindex)

    apply_dehntwist!(pd, pantindex, bdyindex, direction)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))


    generate_new_branchencodings(branchencodings, compiledrules2)
end

function encodings_after_firstmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, curveindex::Int, branchencodings::Array{ArcInPants})

    pantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
    bdyindex = findfirst(i->abs(pantscurve_nextto_pant(pd, pantindex, i)) != abs(curveindex), 1:3)

    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_FIRSTMOVE, pantindex, bdyindex)

    apply_firstmove!(pd, curveindex)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    generate_new_branchencodings(branchencodings, compiledrules2)
end

function encodings_after_secondmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, curveindex::Int, branchencodings::Array{ArcInPants})
    upperpantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
    upperbdyindex = bdyindex_nextto_pantscurve(pd, curveindex, LEFT)
    lowerpantindex = pant_nextto_pantscurve(pd, curveindex, RIGHT)
    lowerbdyindex = bdyindex_nextto_pantscurve(pd, curveindex, RIGHT)
    
    compiledrules1 = [
        compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_SECONDMOVE, upperpantindex, upperbdyindex); 
        compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_SECONDMOVE[1:length(REPLACEMENT_RULES_SECONDMOVE)-1], lowerpantindex, lowerbdyindex)
    ]

    apply_secondmove!(pd, curveindex)
    
    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch_twopants(pd, newdata..., upperpantindex, lowerpantindex))

    generate_new_branchencodings(branchencodings, compiledrules2)
end


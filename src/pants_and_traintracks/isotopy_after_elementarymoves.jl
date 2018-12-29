
module IsotopyAfterElementaryMoves

export update_encodings_after_halftwist!, update_encodings_after_dehntwist!, update_encodings_after_firstmove!, update_encodings_after_secondmove!

using Donut.Constants
using Donut.TrainTracks
using Donut.Pants
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.Pants.ElementaryMoves
using Donut.PantsAndTrainTracks.DehnThurstonTracks: findbranch, arc_in_pantsdecomposition
using Donut.PantsAndTrainTracks.PathTightening: reversedpath

function replacement_rules_twist(twistdirection::Side=RIGHT)
    # idx1, idx2, idx3 = bdyindex, nextindex(bdyindex, 3), previndex(bdyindex, 3)
    sg = twistdirection == RIGHT ? 1 : -1
    return [
        ((BRIDGE, 3), [(PANTSCURVE, -sg), (BRIDGE, 3)]),
        ((BRIDGE, 2), [(BRIDGE, 2), (PANTSCURVE, sg)]),
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

const REPLACEMENT_RULES_FIRSTMOVE_INVERSE = [
    ((BRIDGE, 1), [(PANTSCURVE, -2)]),
    ((BRIDGE, 2), [(PANTSCURVE, 2), (BRIDGE, 2)]),
    ((BRIDGE, 3), [(BRIDGE, -2)]),
    ((PANTSCURVE, 2), [(BRIDGE, 1)]),
    ((SELFCONN, 1), [(BRIDGE, -2), (BRIDGE, -3)])
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


function compile_oldbranch(dttraintrack::TrainTrack, pd::PantsDecomposition, 
    branchencodings::Vector{ArcInPants}, branchtype::PantsArcType, bdyindex::BdyIndex, 
    pantindex::Int, marking_bdyindex::BdyIndex)
    indices = marking_bdyindex, nextindex(marking_bdyindex), previndex(marking_bdyindex)
    findbranch(dttraintrack, pd, pantindex, indices[Int(bdyindex)], branchtype, branchencodings)
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
function compile_oldbranches(dttraintrack::TrainTrack, pd::PantsDecomposition, 
    branchencodings::Vector{ArcInPants}, replacement_rules, pantindex::Int, 
    marking_bdyindex::BdyIndex)
    ret = []
    for rule in replacement_rules
        br = compile_oldbranch(dttraintrack, pd, branchencodings, rule[1][1], 
            BdyIndex(rule[1][2]), pantindex, marking_bdyindex)
        if br != nothing
            push!(ret, (br, rule[2]))
        end
    end
    ret
end

function compile_newbranch(pd_aftermove::PantsDecomposition, branchtype::PantsArcType, 
    bdyindex::Int, pantindex::Int, marking_bdyindex::BdyIndex)
    indices = (marking_bdyindex, nextindex(marking_bdyindex), previndex(marking_bdyindex))
    arc_in_pantsdecomposition(pd_aftermove, pantindex, indices[abs(bdyindex)], bdyindex < 0, branchtype)
end

function compile_newbranch_twopants(pd_aftermove::PantsDecomposition, branchtype::PantsArcType, 
    bdyindex::Int, side::Side, leftpantindex::Int, rightpantindex::Int)
    # println(pd_aftermove)
    arc_in_pantsdecomposition(pd_aftermove, side == LEFT ? leftpantindex : rightpantindex, 
        BdyIndex(abs(bdyindex)), bdyindex < 0, branchtype)
end

function compile_newbranches(replacement_rules, compile_fn::Function)
    [(br, [compile_fn(item) for item in newdata]) for (br, newdata) in replacement_rules]
end

function update_branchencodings!(branchencodings::Vector{ArcInPants}, 
        compiledrules::Vector{Tuple{Int16, Vector{ArcInPants}}})
    encoding_changes = Tuple{Int16, Vector{ArcInPants}}[]
    for (br, newencoding) in compiledrules
        if br > 0
            push!(encoding_changes, (br, newencoding))
        else
            push!(encoding_changes, (-br, reversedpath(newencoding)))
        end
    end
    encoding_changes
end

# TODO: implement an inverse half twist. For now a half-twist plus and inverse Dehn twist does the job.
function update_encodings_after_halftwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, 
    pantindex::Int, bdyindex::BdyIndex, branchencodings::Vector{ArcInPants})
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, REPLACEMENT_RULES_HALFTWIST, pantindex, bdyindex)

    apply_halftwist!(pd, pantindex, bdyindex)

    compiledrules2 = compile_newbranches(compiledrules1, newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_dehntwist!(dttraintrack::TrainTrack, pd::PantsDecomposition, 
    pantindex::Int, bdyindex::BdyIndex, direction::Side, branchencodings::Vector{ArcInPants})
    # println("*******************************")
    # println("Compiling old branches...")
    # println("*******************************")
    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, 
        replacement_rules_twist(direction), pantindex, bdyindex)
    # println("*******************************")
    # println(direction)
    # println(replacement_rules_twist(direction))
    # println(compiledrules1)
    # println("*******************************")

    apply_dehntwist!(pd, pantindex, bdyindex, direction)

    compiledrules2 = compile_newbranches(compiledrules1, 
        newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    # println(compiledrules2)
    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_firstmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, 
        curveindex::Int, branchencodings::Vector{ArcInPants}, inverse=false)

    pantindex = pant_nextto_pantscurve(pd, curveindex, LEFT)
    idx = findfirst(i->abs(pantscurve_nextto_pant(pd, pantindex, BdyIndex(i))) !=
        abs(curveindex), 1:3)
    bdyindex = BdyIndex(idx)

    compiledrules1 = compile_oldbranches(dttraintrack, pd, branchencodings, 
        inverse ? REPLACEMENT_RULES_FIRSTMOVE_INVERSE : REPLACEMENT_RULES_FIRSTMOVE, 
        pantindex, bdyindex)

    apply_firstmove!(pd, curveindex)

    compiledrules2 = compile_newbranches(compiledrules1, 
        newdata->compile_newbranch(pd, newdata..., pantindex, bdyindex))

    update_branchencodings!(branchencodings, compiledrules2)
end

function update_encodings_after_secondmove!(dttraintrack::TrainTrack, pd::PantsDecomposition, 
        curveindex::Int, branchencodings::Vector{ArcInPants})
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
        compile_oldbranches(dttraintrack, pd, branchencodings, 
            REPLACEMENT_RULES_SECONDMOVE_UPPER, upperpantindex, upperbdyindex); 
        compile_oldbranches(dttraintrack, pd, branchencodings, 
            REPLACEMENT_RULES_SECONDMOVE_LOWER[1:length(REPLACEMENT_RULES_SECONDMOVE_LOWER)-1], 
            lowerpantindex, lowerbdyindex)
    ]

    apply_secondmove!(pd, curveindex)
    
    # println("CP1: ", compiledrules1)
    compiledrules2 = compile_newbranches(compiledrules1, 
        newdata->compile_newbranch_twopants(pd, newdata..., upperpantindex, lowerpantindex))
    # println("CP2: ", compiledrules2)

    update_branchencodings!(branchencodings, compiledrules2)
end



end
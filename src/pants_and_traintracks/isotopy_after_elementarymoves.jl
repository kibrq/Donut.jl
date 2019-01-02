
module IsotopyAfterElementaryMoves

export update_encodings_aftermove!

using Donut.Constants
using Donut.TrainTracks
using Donut.Pants
using Donut.PantsAndTrainTracks.ArcsInPants
using Donut.Pants.ElementaryMoves
using Donut.PantsAndTrainTracks.DehnThurstonTracks: findbranch, arc_in_pantsdecomposition
using Donut.PantsAndTrainTracks.PathTightening
using Donut.PantsAndTrainTracks.Paths


function replacement_rules(move::Twist)
    # idx1, idx2, idx3 = bdyindex, nextindex(bdyindex, 3), previndex(bdyindex, 3)
    sg = move.direction == RIGHT ? 1 : -1
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
const REPLACEMENT_RULES_SECONDMOVE = [REPLACEMENT_RULES_SECONDMOVE_UPPER; REPLACEMENT_RULES_SECONDMOVE_LOWER]

function replacement_rules(move::FirstMove)
    !move.isinverse ? REPLACEMENT_RULES_FIRSTMOVE : REPLACEMENT_RULES_FIRSTMOVE_INVERSE
end


replacement_rules(move::HalfTwist) = REPLACEMENT_RULES_HALFTWIST

@enum UpperOrLower UPPER LOWER

function replacement_rules(move::SecondMove)
    REPLACEMENT_RULES_SECONDMOVE
end

function compile_oldbranch(dttraintrack::DecoratedTrainTrack, pd::PantsDecomposition, 
    branchencodings::Vector{Path{ArcInPants}}, branchtype::PantsArcType, bdyindex::BdyIndex, 
    pantindex::Integer, marking_bdyindex::BdyIndex)
    indices = marking_bdyindex, nextindex(marking_bdyindex), previndex(marking_bdyindex)
    findbranch(dttraintrack, pd, pantindex, indices[Int(bdyindex)], branchtype, branchencodings)
end

function compile_oldbranches(dttraintrack::DecoratedTrainTrack, 
    pd::PantsDecomposition, branchencodings::Vector{Path{ArcInPants}}, 
    rules, pantindex::Integer, marking_bdyindex::BdyIndex, 
    branches_to_change::Vector{Int16})
    for i in 1:length(rules)
        branch = compile_oldbranch(dttraintrack, pd, branchencodings, 
            rules[i][1][1], BdyIndex(rules[i][1][2]), pantindex, marking_bdyindex)
        push!(branches_to_change, branch == nothing ? 0 : branch)
    end
end


function compile_newbranch(pd_aftermove::PantsDecomposition, branchtype::PantsArcType, 
    signed_bdyindex::Integer, pantindex::Integer, marking_bdyindex::BdyIndex)
    indices = (marking_bdyindex, nextindex(marking_bdyindex), previndex(marking_bdyindex))
    arc_in_pantsdecomposition(pd_aftermove, pantindex, indices[abs(signed_bdyindex)], 
        signed_bdyindex < 0, branchtype)
end



function update_branchencodings!(branchencodings::Vector{Path{ArcInPants}},
        rules, old_branches::AbstractArray{Int16}, compile_fn::Function)
    for (i, br) in enumerate(old_branches)
        if br != 0
            newbranch_rules = rules[i][2]
            path = branchencodings[abs(br)]
            empty!(path)
            for rule in newbranch_rules
                newencoding = compile_fn(rule)
                # newencoding = compile_newbranch(pd, rule[1], rule[2], pantindex, marking_bdyindex)
                if br > 0
                    push!(path, newencoding)
                else
                    push!(reverse(path), newencoding)
                end
            end
        end
    end
end



get_pantindex(pd::PantsDecomposition, move::HalfTwist) = 
    pant_nextto_pantscurve(pd, move.curveindex, move.side)
get_pantindex(pd::PantsDecomposition, move::Twist) = 
    pant_nextto_pantscurve(pd, move.curveindex, LEFT)
get_pantindex(pd::PantsDecomposition, move::FirstMove) = 
    pant_nextto_pantscurve(pd, move.curveindex, LEFT)
get_bdyindex(pd::PantsDecomposition, move::HalfTwist) = 
    bdyindex_nextto_pantscurve(pd, move.curveindex, move.side)
get_bdyindex(pd::PantsDecomposition, move::Twist) = 
    bdyindex_nextto_pantscurve(pd, move.curveindex, LEFT)
get_bdyindex(pd::PantsDecomposition, move::FirstMove) = 
    BdyIndex(findfirst(i->abs(pantscurve_nextto_pant(pd, get_pantindex(pd, move), BdyIndex(i))) !=
    abs(move.curveindex), 1:3))




# TODO: implement an inverse half twist. For now a half-twist plus and inverse Dehn twist does the job.
function update_encodings_aftermove!(dttraintrack::DecoratedTrainTrack, pd::PantsDecomposition, 
        move::Union{HalfTwist, Twist, FirstMove}, branchencodings::Vector{Path{ArcInPants}},
        branches_to_change::Vector{Int16}=Int16[])
    pantindex = get_pantindex(pd, move)
    marking_bdyindex = get_bdyindex(pd, move)
    rules = replacement_rules(move)

    empty!(branches_to_change)
    compile_oldbranches(dttraintrack, pd, branchencodings, rules,
        pantindex, marking_bdyindex, branches_to_change)

    apply_move!(pd, move)

    update_branchencodings!(branchencodings, rules, branches_to_change, 
        rule->compile_newbranch(pd, rule[1], rule[2], pantindex, marking_bdyindex))
    deletezeros!(branches_to_change)
end


function update_encodings_aftermove!(dttraintrack::DecoratedTrainTrack, 
        pd::PantsDecomposition, move::SecondMove, branchencodings::Vector{Path{ArcInPants}},
        branches_to_change::Vector{Int16}=Int16[])
    upperpantindex = pant_nextto_pantscurve(pd, move.curveindex, LEFT)
    upperbdyindex = bdyindex_nextto_pantscurve(pd, move.curveindex, LEFT)
    lowerpantindex = pant_nextto_pantscurve(pd, move.curveindex, RIGHT)
    lowerbdyindex = bdyindex_nextto_pantscurve(pd, move.curveindex, RIGHT)
    
    empty!(branches_to_change)
    rules = replacement_rules(move)

    compile_oldbranches(dttraintrack, pd, branchencodings, view(rules, 1:7),
        upperpantindex, upperbdyindex, branches_to_change)
    compile_oldbranches(dttraintrack, pd, branchencodings, view(rules, 8:13),
        lowerpantindex, lowerbdyindex, branches_to_change)

    apply_move!(pd, move)
    
    leftpantindex = upperpantindex
    rightpantindex = lowerpantindex
    update_branchencodings!(branchencodings, rules, branches_to_change, 
    rule->compile_newbranch(pd, rule[1], rule[2], 
    rule[3] == LEFT ? leftpantindex : rightpantindex, BdyIndex(1)))

    deletezeros!(branches_to_change)
end




function deletezeros!(v::Vector{Int16})
    for i in length(v):-1:1
        if v[i] == 0
            deleteat!(v, i)
        end
    end
end

end

module MeasuresAndOperations

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Measures: _allocatemore!, _setmeasure!
# using Donut.TrainTrack:
using Donut.Utils: otherside

function updatemeasure_pullswitchapart!(tt_afterop::TrainTrack,
    measure::Measure, newbranch::Int)
    if newbranch > length(measure.values)
        _allocatemore!(measure, newbranch)
    end
    sw = branch_endpoint(tt_afterop, -newbranch)
    newvalue = outgoingmeasure(tt_afterop, measure, -switch) - outgoingmeasure(tt_afterop, measure, switch)
    _setmeasure!(measure, newbranch, newvalue)
end


function updatemeasure_collapse!(tt_afterop::TrainTrack,
    measure::Measure, collapsedbranch::Int)
    _setmeasure!(measure, collapsedbranch, 0)
end

function updatemeasure_renamebranch!(tt_afterop::TrainTrack,
    measure::Measure, oldlabel::Int, newlabel::Int)
    value = branchmeasure(measure, oldlabel)
    _setmeasure!(measure, oldlabel, 0)
    _setmeasure!(measure, newlabel, value)
end

"""
Consider standing at a switch, looking forward. On each side (LEFT, RIGHT), we can peel either the branch going forward or the branch going backward. This function returns FORWARD or BACKWARD, indicating which branch is peeled according to the measure (the one that has smaller measure).
"""
function whichside_to_peel(tt::TrainTrack, measure::Measure, switch::Int, side::Int)
    br1 = outgoing_branch(tt, switch, 1, side)
    br2 = outgoing_branch(tt, -switch, 1, otherside(side))
    branchmeasure(br1) < branchmeasure(br2) ? FORWARD : BACKWARD
end




end
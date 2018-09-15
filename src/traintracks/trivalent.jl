
module Trivalent

export istrivalent, split_trivalent!, is_branch_large

using Donut.TrainTracks
using Donut.Constants: LEFT, RIGHT, CENTRAL
using Donut.TrainTracks.Operations
using Donut.TrainTracks.Operations: BranchRange

istrivalent(tt::TrainTrack) = all(switch_valence(tt, sw) == 3 for sw in switches(tt))

    function is_branch_large(tt::TrainTrack, branch::Int)
        start_sw = branch_endpoint(tt, -branch)
        end_sw = branch_endpoint(tt, branch)
        numoutgoing_branches(tt, end_sw) == 1 && numoutgoing_branches(tt, start_sw) == 1
    end


    """
    Left split: central brach is turning left after the splitting.
    """
    function split_trivalent!(tt::TrainTrack, branch::Int, left_right_or_central::Int)
        if left_right_or_central == CENTRAL
            error("Central splittings are not yet implemented")
        end
    
        if !is_branch_large(tt, branch)
            error("The split branch should be a large branch.")
        end
        start_sw = branch_endpoint(tt, -branch)
        end_sw = branch_endpoint(tt, branch)
        if switch_valence(tt, start_sw) != 3 && switch_valence(tt, end_sw) != 3
            error("The endpoints of the split branch should be trivalent.")
        end
        @assert left_right_or_central in (LEFT, RIGHT, CENTRAL)
    
        collapse_branch!(tt, branch)
        side = left_right_or_central == CENTRAL ? LEFT : left_right_or_central
        new_sw, new_br = pull_switch_apart!(tt, BranchRange(start_sw, 1:1, side),
                           BranchRange(-start_sw, 1:1, side))
    
        if left_right_or_central == CENTRAL
            delete_branch!(tt, new_br)
            delete_two_valent_switch!(tt, new_sw)
            delete_two_valent_switch!(tt, sw)
            # TODO: What do we do when this would remove the last switch of the train track?
        end
    end
    

end
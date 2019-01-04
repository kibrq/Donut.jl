module Donut

import Base: *, ==, ^, inv, copy

export 
# constants
LEFT, RIGHT, FORWARD, BACKWARD,

# surfaces
Surface, genus, numpunctures, isorientable, eulerchar, 
surface_from_eulerchar, homologydim, teichspacedim,

# markings 
PantsDecomposition, Triangulation, regions, numregions, numboundarycurves, 
boundarycurves, innercurves, separators, isboundary_pantscurve, 
isinner_pantscurve, separator_to_region, separator_to_bdyindex, 
region_to_separator, region_to_separators, gluinglist, isfirstmove_curve, 
issecondmove_curve,

FirstMove, SecondMove, HalfTwist, Twist, apply_move!,

# train tracks
TrainTrack, branch_endpoint, numoutgoing_branches, outgoing_branches, istwisted, 
switches, branches, isbranch, isswitch, is_branch_large, 
switchvalence, istrivalent, extremal_branch, 
next_branch, numswitches, numbranches, twist_branch!,

# measures
hasmeasure, branchmeasure, add_measure!,

# cusps
hascusphandler, cusp_to_branch, branch_to_cusp, cusp_to_switch, cusps, numcusps,

# train track operations
apply_tt_operation!, Peel, Fold, PulloutBranches, 
CollapseBranch, RenameBranch, RenameSwitch, ReverseBranch, ReverseSwitch,
DeleteBranch, DeleteTwoValentSwitch, AddSwitchOnBranch,
SplitTrivalent, FoldTrivalent, LEFT_SPLIT, 
RIGHT_SPLIT, CENTRAL_SPLIT, 

# carrying maps
CarryingMap, 

# laminations
PantsLamination, lamination_from_pantscurve, lamination_from_transversal, 
lamination_to_dtcoords, DehnThurstonCoordinates, TriangleCoordinates,
intersection_number, twisting_number, dehnthurstontrack, 
measured_dehnthurstontrack,

# mapping classes
pantstwist, transversaltwist, halftwist, identity_mapping_class,
isidentity_upto_homology, hyperelliptic_involution,

# generating sets 
humphries_generators


# Submodules
include("constants.jl")
include("surface.jl")

include("markings/markedsurfaces.jl")
include("markings/changeofmarkings.jl")

include("traintracks/base.jl")
include("traintracks/operations.jl")
include("traintracks/measures.jl")
include("traintracks/cusps.jl")
include("traintracks/traintracks.jl")
include("traintracks/carrying.jl")
include("traintracks/traintracknets.jl")

include("tightening/arcs.jl")
include("tightening/paths.jl")
include("tightening/path_tightening.jl")

include("laminations/lamination_coordinates.jl")
include("laminations/standard_traintracks.jl")
include("laminations/measured_dehnthurstontracks.jl")
include("laminations/isotopy_after_elementarymoves.jl")
include("laminations/peel_fold.jl")
include("laminations/pantslaminations.jl")

include("mappingclasses/pants_mapping_classes.jl")
include("mappingclasses/generating_sets.jl")
include("mappingclasses/examples.jl")




export ElementaryTTOperation, TTOperation, Peel, Fold, PulloutBranches, 
    CollapseBranch, RenameBranch, RenameSwitch, ReverseBranch, ReverseSwitch,
    DeleteBranch, DeleteTwoValentSwitch, AddSwitchOnBranch,
    SplitTrivalent, FoldTrivalent, TrivalentSplitType, LEFT_SPLIT, 
    RIGHT_SPLIT, CENTRAL_SPLIT, convert_to_elementaryops

    export TrainTrackNet, get_tt, add_traintrack!, add_carryingmap_as_small_tt!,
    apply_tt_operation!

    export TrainTrack, branch_endpoint, numoutgoing_branches, outgoing_branches, istwisted, 
    switches, branches, isbranch, isswitch, is_branch_large, 
    switchvalence, istrivalent, extremal_branch, 
    cusp_to_branch, branch_to_cusp, cusp_to_switch, cusps,
    next_branch, numcusps, numswitches, numbranches, add_measure!, branchmeasure,
    apply_tt_operation!

    export pantstwist, transversaltwist, PantsMappingClass

end

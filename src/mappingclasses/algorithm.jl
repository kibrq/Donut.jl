

function invariant_tt(mc::MappingClass)
    # We pick a curve.
    # TODO: Pick another that fill the surface with this one, 
    # or a larger collection of filling curves.
    # Just one curve will do it in the pseudo-Anosov case, though.
    lam = example_curve(mc)
    surface = marked_surface(mc)

    # TODO: Write this function independently of the pants vs
    # triangulation marking.

    # TODO: figure out the list of exponents we have to look at. 
    for exp in 1:eulerchar(surface)^2
        # Computing an iterate of the curve
        apply_mappingclass_to_lamination!(mc^exp, lam)

        # The lamination lam is represented as a measured Dehn-Thurston
        # train track. We create a CarryingMap from this.

        ttnet = TrainTrackNet()
        small_dtt = TrainTrack(lam.tt, measure=lam.measure)
        small_tt_index = add_traintrack!(ttnet, small_dtt)
        large_tt_index1 = add_carryingmap_as_small_tt!(ttnet, small_tt_index)
        large_tt_index2 = add_carryingmap_as_small_tt!(ttnet, small_tt_index)

        # Make the small train track trivalent.
        make_tt_trivalent!(ttnet, small_tt_index)
    end
end



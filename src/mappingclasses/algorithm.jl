module Algorithm

using Donut.TrainTracks.Carrying
using Donut.MappingClasses

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
        tt = lam.tt
        measure = lam.measure
        cm = CarryingMap(tt)

        # Make the small train track trivalent.
        make_small_tt_trivalent!(cm, measure)
    end
end



end
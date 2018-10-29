
module GeneratingSets

using Donut.Pants
using Donut.MappingClasses

function humphries_generators(genus::Int, rightmost_included::Bool=false)
    pd = pantsdecomposition_humphries(genus)
    A = [pantstwist(1)]
    for i in 1:genus-1
        push!(A, transversaltwist(pd, 3*i-1))
    end
    B = [transversaltwist(pd, 1)]
    for i in 1:genus-2
        move1, move2 = SecondMove(3*i), FirstMove(3*i+1)
        push!(PantsMappingClass([move1, move2, pantstwist(3*i+1), inverse(move1), inverse(move2)]))
    end
    push!(B, transversaltwist(pd, 3*genus-3))
    c = pantstwist(3)
    if right_most_included
        push!(A, pantstwist(3*genus-3))
    end
    pd, A, B, c
end


end
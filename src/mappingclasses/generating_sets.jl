



function humphries_generators(genus::Int, rightmost_included::Bool=false)
    pd = pantsdecomposition_humphries(genus)
    A = [pantstwist(pd, 1)]
    for i in 1:genus-1
        push!(A, transversaltwist(pd, 3*i-1))
    end
    B = [transversaltwist(pd, 1)]
    for i in 1:genus-2
        move1, move2 = SecondMove(3*i), FirstMove(3*i+1)
        fi = PantsMappingClass(pd, [move1, move2, Twist(3*i+1), inverse(move2), inverse(move1)])
        push!(B, fi)
    end
    push!(B, transversaltwist(pd, 3*genus-3))
    c = pantstwist(pd, 3)
    if rightmost_included
        push!(A, pantstwist(pd, 3*genus-3))
    end
    A, B, c
end


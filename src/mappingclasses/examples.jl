module Examples

using Donut.MappingClasses: postcompose!
using Donut.MappingClasses.GeneratingSets


"""Construct the hyperelliptic involution on a closed surface.

INPUT:

- ``genus`` -- the genus of the closed surface

EXAMPLE:

    >>> from macaw.examples import hyperelliptic_involution
    >>> g = hyperelliptic_involution(3)

"""
function hyperelliptic_involution(genus)
    pd, A, B, c = humphries_generators(genus, right_most_included=True)

    f = A[0]
    # print c
    # print A[-1]
    for i in 1:genus
        postcompose!(f, B[i])
        postcompose!(f, A[i+1])
    end
    for i in 1:genus
        postcompose!(f, A[genus-i+1])
        postcompose!(f, B[genus-i])
    end
    postcompose!(f, A[1])
    return f
end


end




"""Construct the hyperelliptic involution on a closed surface.

INPUT:

- ``genus`` -- the genus of the closed surface

EXAMPLE:

    >>> from macaw.examples import hyperelliptic_involution
    >>> g = hyperelliptic_involution(3)

"""
function hyperelliptic_involution(genus)
    A, B, c = humphries_generators(genus, true)

    f = copy(A[1])
    # print c
    # print A[-1]
    for i in 1:genus
        # println(i)
        postcompose!(f, B[i])
        postcompose!(f, A[i+1])
    end
    for i in 1:genus
        postcompose!(f, A[genus-i+2])
        postcompose!(f, B[genus-i+1])
    end
    postcompose!(f, A[1])
    return f
end

# f = A[0]
# # print c
# # print A[-1]
# # print c == A[-1]
# for i in range(g):
#     f = f * B[i]
#     f = f * A[i+1]
# for i in range(g):
#     f = f * A[g-i]
#     f = f * B[g-i-1]
# f *= A[0]
# return f


using Donut.MappingClasses.GeneratingSets

A, B, c = humphries_generators(2)

function test()
    A[1]*A[2] == A[2]*A[1]
    A[1]*B[2] == B[2]*A[1]
    A[1]*c == c*A[1]
    A[1]*B[1] != B[1]*A[1]
    A[1]*B[1]*A[1] == B[1]*A[1]*B[1]
    B[1]*c == c*B[1]
    B[1]*B[2] == B[2]*B[1]
    B[1]*A[2] != A[2]*B[1]
    B[1]*A[2]*B[1] == A[2]*B[1]*A[2]
    A[2]*c == c*A[2]
    A[2]*B[2] != B[2]*A[2]
    A[2]*B[2]*A[2] == B[2]*A[2]*B[2]
    B[2]*c != c*B[2]
    B[2]*c*B[2] == c*B[2]*c
    nothing
end

function test_single()
    A[1]*B[1]*A[1] == B[1]*A[1]*B[1]
end

@time test()
@time test()

# Running time of test()
# - 93ms
# - 85ms: restricting the curvenumbering of PantsDecompositions from 1 to N
# - 70ms: innercurveindixes() returns a generator instead of an array.

# - it was 262ms for the old Python PantsLamination implementation that used Penner's update rules for Dehn-Thurston coordinates
# - it was 380ms for the newer Python PantsLamination implementation that measured train tracks are splitting-folding for updating the coordinates. Only the second move used an automatic peel-fold mechanism, the peel-fold sequences in the other cases were hard-coded.

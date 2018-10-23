module Utils

otherside(side::Int) = (@assert side in (1,2); side == 1 ? 2 : 1)

function nextindex(index::Int, modulo::Int)
    @assert 1 <= index <= modulo
    index == modulo ? 1 : index + 1
end

function previndex(index::Int, modulo::Int)
    @assert 1 <= index <= modulo
    index == 1 ? modulo : index - 1
end

# function addmodulo(index1::Int, index2::Int, modulo::Int)
#     x = (index1 + index2) % modulo
#     x == 0 ? modulo : x
# end

end

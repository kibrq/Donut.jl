


struct Path{T}
    elements::Vector{T}
    isreversed::Bool
end

Path{T}(x) where T = Path{T}(x, false)

Base.length(path::Path) = length(path.elements)

Base.copy(path::Path{T}) where T = Path{T}(copy(path.elements), path.isreversed)

function Base.show(io::IO, path::Path)
    print(io, "Path[")
    for x in path
        print(io, x, ",")
    end
    print(io, "]")
end

function Base.iterate(path::Path, state::Int=0)
    state += 1
    if state > length(path)
        return nothing
    else
        return (path[state], state)
    end
end

Base.getindex(path::Path, i::Integer) = !path.isreversed ? path.elements[i] : 
    reversed_arc(path.elements[length(path)+1-i])

reversed_path(path::Path{T}) where T = Path{T}(path.elements, !path.isreversed)

function Base.splice!(path::Path{T}, range::UnitRange{Int}, replacement::Path{T}) where T
    if !path.isreversed
        splice!(path.elements, range, replacement)
    else
        # splice!(path.elements, length(path)+1-range.stop:length(path)+1-range.start,
        # (reverse(x) for x in Iterators.reverse(replacement)))
        splice!(path.elements, length(path)+1-range.stop:length(path)+1-range.start,
        reversed_path(replacement))
    end
end

function Base.splice!(path::Path, range::UnitRange{Int}, replacement)
    if !path.isreversed
        splice!(path.elements, range, replacement)
    else
        splice!(path.elements, length(path)+1-range.stop:length(path)+1-range.start,
        (reversed_arc(x) for x in Iterators.reverse(replacement)))
    end
end

Base.empty!(path::Path) = empty!(path.elements)

function Base.push!(path::Path{T}, element::T) where T 
    if !path.isreversed
        push!(path.elements, element)
    else
        pushfirst!(path.elements, reversed_arc(element))
    end
end


function Base.append!(add_to_path::Path{T}, added_path::Path{T}) where {T}
    splice!(add_to_path, length(add_to_path)+1:length(add_to_path), added_path)
end

function subtract!(subtract_from_path::Path{T}, subtracted_path::Path{T}) where {T}
    splice!(subtract_from_path, 1:length(subtracted_path), [])
end


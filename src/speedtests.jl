
abstract type Letter end

struct A <: Letter
    x::Int
end
value(z::A) = z.x

struct B <: Letter
    x::Int
end
value(z::B) = -z.x


struct C <: Letter
    x::Int
end
value(z::C) = 2*z.x


struct D <: Letter
    x::Int
end
value(z::D) = -2*z.x

struct E <: Letter
    x::Int
end
value(z::E) = 3*z.x

function create_letter_array(n=10000)
    arr = A[]
    for i in 1:n
        push!(arr, A(1))
        push!(arr, A(1))
        push!(arr, A(1))
        push!(arr, A(1))
        push!(arr, A(1))
        # push!(arr, B(1))
        # push!(arr, C(1))
        # push!(arr, D(1))
        # push!(arr, E(1))
    end
    arr
end

function sum_letter_array(arr::Array{A, 1})
    x = 0
    # sum(value(letter) for letter in arr)
    for letter in arr
        x += value(letter)
        x += 1
        x += letter.x
    end
    x
end


#--------------------------------------

struct CompactLetter
    lettertype::Int
    x::Int
end

function value(letter::CompactLetter)
    if letter.lettertype == 1
        return letter.x
    elseif letter.lettertype == 2
        return -letter.x
    elseif letter.lettertype == 3
        return 2*letter.x
    elseif letter.lettertype == 4
        return -2*letter.x
    elseif letter.lettertype == 5
        return 3*letter.x
    else
        @assert false
    end
end

function create_compactletter_array(n=10000)
    arr = CompactLetter[]
    for i in 1:n
        push!(arr, CompactLetter(1, 1))
        push!(arr, CompactLetter(2, 1))
        push!(arr, CompactLetter(3, 1))
        push!(arr, CompactLetter(4, 1))
        push!(arr, CompactLetter(5, 1))
    end
    arr
end

function sum_compactletter_array(arr::Array{CompactLetter})
    sum(2*value(letter) for letter in arr)
    # x = 0
    # for letter in arr
    #     x += value(letter)
    # end
    # x
end


# ------------------------------------

t = 10000000
@time arr = create_letter_array(t)  # 5s
@time println(sum_letter_array(arr)) # 5s

@time arr = create_compactletter_array(t) # 5s
@time println(sum_compactletter_array(arr)) # 0.05s

# It seems that computing with arrays with abstract type are a lot slower.
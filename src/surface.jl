

abstract type AbstractSurface end



"""
Compact surface with finitely many of points removed.
"""
struct Surface <: AbstractSurface
    genus::Int16
    numpunctures::Int16
    isorientable::Bool

    function Surface(genus::Integer=0, numpunctures::Integer=0, isorientable::Bool=true)
        if !isorientable
            if genus < 1
                error("The genus of a nonorientable surface should be positive.")
            end
        else
            if genus < 0
                error("The genus of an orientable surface should be nonnegative.")
            end
        end
        if numpunctures < 0
            error("The number of punctures should be a nonnegative integer.")
        end

        new(genus, numpunctures, isorientable)
    end
end

function surface_from_eulerchar(eulerchar::Integer=2, numpunctures::Integer=0, isorientable::Bool=true)
    genus = 2 - numpunctures - eulerchar
    if isorientable
        if genus % 2 == 1
            error("Parity of the number of punctures and Euler characteristic do not match.")
        else
            genus = div(genus, 2)
        end
    end
    Surface(genus, numpunctures, isorientable)
end


genus(s::Surface) = s.genus
numpunctures(s::Surface) = s.numpunctures
isorientable(s::Surface) = s.isorientable

eulerchar(s::AbstractSurface) = isorientable(s) ?
    2-2*genus(s)-numpunctures(s) : 2-genus(s)-numpunctures(s)
homologydim(s::AbstractSurface) = isorientable(s) ? 2 * genus(s) + max(numpunctures(s)-1, 0) :
    genus(s) - 1 + numpunctures(s)

function teichspacedim(s::AbstractSurface)
    if isorientable(s)
        if genus(s) == 0 && numpunctures(s) <= 3
            0
        elseif genus(s) == 1 && numpunctures(s) == 0
            2
        else
            6 * genus(s) - 6 + 2 * numpunctures(s)
        end
    else
        if genus(s) == 1 && numpunctures(s) <= 1
            0
        elseif genus(s) == 2 && numpunctures(s) == 0
            1
        else
            3 * genus(s) - 6 + 2 * numpunctures(s)
        end
    end
end

function repr(s::Surface)
    if isorientable(s)
        if genus(s) == 0
            str = "Sphere"
            if numpunctures(s) == 1
                return "Disk"
            elseif numpunctures(s) == 2
                return "Annulus"
            end
        elseif genus(s) == 1
            str = "Torus"
        else
            str = "Surface of genus $(genus(s))"
        end
    else
        if genus(s) == 1
            if numpunctures(s) == 1
                return "Mobius strip"
            end
            str = "Projective plane"
        elseif genus(s) == 2
            str = "Klein bottle"
        else
            str = "Nonorientable surface of genus $(genus(s))"
        end
    end

    if numpunctures(s) == 0
        if isorientable(s) && genus(s) <= 1 || !isorientable(s) && genus(s) <= 2
            return str
        else
            return "Closed $(lowercase(str))"
        end
    else
        str *= " with $(numpunctures(s)) puncture"
        if numpunctures(s) >= 2
            str *= "s"
        end
    end
    return str
end

Base.show(io::IO, s::Surface) = print(io, repr(s))


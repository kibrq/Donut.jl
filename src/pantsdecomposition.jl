struct Pant
    boundaries::Array{Int, 1}  # length 3
end

struct PantsCurve
    neighboring_pants::Array{Int, 1}  # length 2
    is_orientation_reversing::Array{Bool, 1}  # length 2
end



struct PantsDecomposition <: AbstractSurface
    pants::Array{Pant, 1}
    pants_curves::Array{PantsCurve, 1}

    # gluinglist will not be deepcopied, it is owned by the object
    function PantsDecomposition(gluinglist::Array{Array{Int, 1}, 1})
        num_pants = length(gluinglist)
        pants = [Pant() for i in 1:num_pants]
        for i in 1:num_pants
            ls = gluinglist[i]
            if length(ls) != 3
                error("All pants should have three boundaries")
            end
        end
        pants = [Pant(ls) for ls in gluinglist]

        pants_curves



        new(pants, pants_curves)
    end



end

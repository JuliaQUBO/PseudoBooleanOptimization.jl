function aux(counter::Vector{Int}, n::Union{Integer,Nothing})
    if isnothing(n)
        return first(aux(counter, 1))
    else
        return [Symbol("aux_$(counter[] += 1)") for _ in 1:n]
    end
end

function test_NTR_KZFD()
    @testset "NTR-KZFD" begin
        
    end

    return nothing
end

function test_PTR_BG()
    @testset "PTR-BG" begin

    end

    return nothing
end

function test_quadratization()
    @testset "Quadratization" begin
        test_NTR_KZFD()
        test_PTR_BG()
    end

    return nothing
end
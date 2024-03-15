@doc raw"""
    not_all_equal_3sat(rng, n::Integer, m::Integer)

Generates Not-all-equal 3-SAT problem with ``m`` variables and ``n`` clauses.
"""
function not_all_equal_3sat end

function not_all_equal_3sat(rng, ::Type{F}, n::Integer, m::Integer) where {V,T,F<:AbstractPBF{V,T}}
    J = Dict{Tuple{Int,Int},T}()

    C = BitSet(1:n)

    c = Vector{Int}(undef, 3)
    s = Vector{Int}(undef, 3)

    for _ = 1:m
        union!(C, 1:n)

        for j = 1:3
            c[j] = pop!(C, rand(rng, C))
        end
        
        s .= rand(rng, (-1,+1), 3)

        for i = 1:3, j = (i+1):3 # i < j
            x = (c[i], c[j])

            J[x] = get(J, x, zero(T)) + s[i] * s[j]
        end
    end

    # Convert to boolean
    # s = 2x - 1
    f = sum([J[i,j] * F(i => T(2), T(-1)) * F(j => T(2), T(-1)) for (i,j) in keys(J)])
    x = nothing # no planted solutions

    return (f, x)
end

function not_all_equal_3sat(::Type{F}, n::Integer, m::Integer) where {V,T,F<:AbstractPBF{V,T}}
    return not_all_equal_3sat(Random.GLOBAL_RNG, F, n, m)
end

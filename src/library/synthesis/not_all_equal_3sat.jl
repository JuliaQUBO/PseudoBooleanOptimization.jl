@doc raw"""
    not_all_equal_3sat(rng, n::Integer, m::Integer)

Generates Not-all-equal 3-SAT problem with ``m`` variables and ``n`` clauses.
"""
function not_all_equal_3sat end

function not_all_equal_3sat(
    rng,
    ::Type{F},
    n::Integer,
    m::Integer,
) where {V,T,F<:AbstractPBF{V,T}}
    J = Dict{Tuple{Int,Int},T}()

    C = BitSet(1:n)

    c = Vector{Int}(undef, 3)
    s = Vector{Int}(undef, 3)

    for _ = 1:m
        union!(C, 1:n)

        for j = 1:3
            c[j] = pop!(C, rand(rng, C))
        end

        s .= rand(rng, (-1, +1), 3)

        for i = 1:3, j = (i+1):3 # i < j
            x = (c[i], c[j])

            J[x] = get(J, x, zero(T)) + s[i] * s[j]
        end
    end

    # Convert to boolean
    # let s_i = 2x_i - 1
    # ⟹ s_i s_j = (2x_i - 1) (2x_j - 1) = 4x_i x_j - 2x_i - 2x_j + 1
    # ⟹ Jij s_i s_j = 4Jij x_i x_j - 2Jij x_i - 2Jij x_j + Jij
    f = sizehint!(zero(F), length(J) + n)

    for ((i, j), c) in J
        xi = varmap(V, i)
        xj = varmap(V, j)

        f[xi, xj]  += 4c
        f[xi]      -= 2c
        f[xj]      -= 2c
        f[nothing] += c
    end

    return (f, Dict{V,Int}[]) # no planted solutions
end

function not_all_equal_3sat(
    ::Type{F},
    n::Integer,
    m::Integer,
) where {V,T,F<:AbstractPBF{V,T}}
    return not_all_equal_3sat(Random.GLOBAL_RNG, F, n, m)
end

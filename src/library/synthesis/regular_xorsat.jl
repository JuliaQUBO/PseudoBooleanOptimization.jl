@doc raw"""
    k_regular_k_xorsat

Generates a ``k``-regurlar ``k``-XORSAT instance with ``n`` boolean variables.
"""
function k_regular_k_xorsat(
    rng,
    ::Type{F},
    n::Integer,
    k::Integer;
    quad::Union{Quadratization,Nothing} = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    idx = zeros(Int, n, k)

    for j = 1:k, i = 1:n
        idx[i, j] = i
    end

    A = Matrix{Int}(undef, n, n)
    b = Vector{Int}(undef, n)
    c = Vector{Int}(undef, n)

    u = Vector{Int}(undef, n)

    while true
        while true
            _colwise_shuffle!(rng, idx)

            if _rowwise_allunique(idx, u)
                break
            end
        end

        A .= 0

        for i = 1:n, j = 1:k
            A[i, idx[i, j]] = 1
        end

        rand!(rng, b, (0, 1))

        c .= b # copy values before elimination

        x = _mod2_solution!(A, b)

        if !isnothing(x)
            # Convert to boolean
            # s = 2x - 1
            # If ∑ⱼ xᵢⱼ ≡ cᵢ (mod 2), then ∏ⱼ(2xᵢⱼ - 1) = (-1)^(k - cᵢ).
            # Scale each clause by (-1)^(k + cᵢ + 1) so every satisfied clause contributes -1.
            f = sum(
                (-one(T))^(k + c[i] + 1) *
                prod([F(varmap(V, idx[i, j]) => T(2), -one(T)) for j = 1:k])
                for i = 1:n
            )

            quadratize!(f, quad)

            return (f, Dict{V,Int}[Dict{V,Int}(varmap(V, i) => x[i] for i = 1:n)])
        end
    end

    return nothing
end

function k_regular_k_xorsat(
    ::Type{F},
    n::Integer,
    k::Integer;
    quad::Union{Quadratization,Nothing} = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    return k_regular_k_xorsat(Random.GLOBAL_RNG, F, n, k; quad)
end

"""
    r_regular_k_xorsat(rng, r::Integer, k::Integer; quad::QuadratizationMethod)

Generates a ``r``-regurlar ``k``-XORSAT instance with ``n`` boolean variables.

If ``r = k``, then falls back to [`k_regular_k_xorsat`](@ref).
"""
function r_regular_k_xorsat(
    rng,
    ::Type{F},
    n::Integer,
    r::Integer,
    k::Integer;
    quad::Union{Quadratization,Nothing} = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    if r == k
        return k_regular_k_xorsat(rng, F, n, k; quad)
    else
        # NOTE: This might involve solving Sudoku!
        error(
            "A method for generating r-regular k-XORSAT where r ≂̸ k is not implemented (yet).",
        )

        return nothing
    end
end

function r_regular_k_xorsat(
    ::Type{F},
    n::Integer,
    r::Integer,
    k::Integer;
    quad::Union{Quadratization,Nothing} = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    return r_regular_k_xorsat(Random.GLOBAL_RNG, F, n, r, k; quad)
end

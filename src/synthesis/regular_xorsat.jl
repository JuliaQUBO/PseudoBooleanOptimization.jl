@doc raw"""

Generates a ``k``-regurlar ``k``-XORSAT instance with ``n`` boolean variables.
"""
function k_regular_k_xorsat(
    rng,
    ::Type{F},
    n::Integer,
    k::Integer;
    quad::Union{Quadratization,Nothing} = nothing,
) where {V,T,F<:AbstractFunction{V,T}}
    idx = zeros(Int, n, k)
    col = collect(1:n)

    while true
        # generate candidate
        while true
            for j = 1:k
                idx[:, j] .= shuffle!(rng, col)
            end

            if all(allunique(idx[i, :]) for i = 1:n)
                break
            end
        end

        A = zeros(Int, n, n)

        for i = 1:n, j = 1:k
            A[i, idx[:, j]] .= 1
        end

        b = rand(rng, (0, 1), n)

        num_solutions = _mod2_numsolutions(A, b)

        if num_solutions > 0
            # Convert to boolean
            # s = 2x - 1
            f = sum((T(-1))^(b[i]) * foldl(*, (F(idx[i,j] => T(2), T(-1)) for j = 1:k)) for i = 1:n)

            return quadratize!(f, quad)
        end
    end
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
) where {V,T,F<:AbstractFunction{V,T}}
    if r == k
        return k_regular_k_xorsat(rng, F, n, k; quad)
    else
        # NOTE: This might involve Sudoku solving!
        error("A method for generating r-regular k-XORSAT where r ≂̸ k is not implemented")
    end
end

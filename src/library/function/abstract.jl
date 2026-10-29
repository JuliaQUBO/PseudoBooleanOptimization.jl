function Base.zero(::F) where {V,T,F<:AbstractPBF{V,T}}
    return zero(F)
end

function Base.one(::F) where {V,T,F<:AbstractPBF{V,T}}
    return one(F)
end

function variables(f::AbstractPBF{V,T}) where {V,T}
    x = Set{V}()

    for ω in keys(f)
        union!(x, ω)
    end

    return sort!(collect(x); lt = varlt)
end

function image(f::AbstractPBF{V,T}) where {V,T}
    v = variables(f)
    n = length(v)
    u = Vector{Int}(undef, n)
    x = Dict{V,Int}(vi => 0 for vi in v)
    y = Vector{T}()

    for i = 0:(2^n - 1)
        digits!(u, i; base = 2)

        for (vi, ui) in zip(v, u)
            x[vi] = ui
        end

        push!(y, f(x))
    end
    
    return unique!(sort!(y; lt = varlt))
end

function bounds(f::AbstractPBF)
    return (lowerbound(f), upperbound(f))
end

function degree(f::AbstractPBF)
    return maximum(length.(keys(f)); init = 0)
end

function residual(f::F, x::V) where {V,T,F<:AbstractPBF{V,T}}
    return F(ω => c for (ω, c) ∈ f if (x ∉ ω))
end

function Base.round(f::AbstractPBF; kws...)
    map!(c -> round(c; kws...), f)

    return f
end

function discretize!(f::AbstractPBF{_,T}; tol::T = T(1E-6))  where {_,T}
    ε = mingap(f; tol)

    map!(c -> round(c / ε; digits = 0), f)

    return f
end

function discretize(f::AbstractPBF{V,T}; tol::T = 1E-6) where {V,T}
    return discretize!(copy(f); tol)
end

function derivative(f::F, x::V) where {V,T,F<:AbstractPBF{V,T}}
    return F(ω => f[ω×x] for ω ∈ keys(f) if (x ∉ ω))
end

function gradient(f::F, x::Vector{V}) where {V,T,F<:AbstractPBF{V,T}}
    return F[derivative(f, xi) for xi in x]
end

function maxgap(f::F) where {V,T,F<:AbstractPBF{V,T}}
    return sum(abs(c) for (ω, c) in f if !isempty(ω); init = zero(T))
end

function mingap(f::F; tol::T = 1E-6) where {V,T,F<:AbstractPBF{V,T}}
    return relaxedgcd(collect(values(f)); tol)::T
end

function lowerbound(f::F) where {V,T,F<:AbstractPBF{V,T}}
    return sum((c < zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f; init = zero(T))
end

function upperbound(f::F) where {V,T,F<:AbstractPBF{V,T}}
    return sum((c > zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f; init = zero(T))
end

function _quadratic_linear_and_row_sums(f::AbstractPBF{V,T}, caller::Symbol) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "$caller is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    lin = Dict{V,T}()
    quad_row_sum = Dict{V,T}()
    vars = Set{V}()

    for (ω, c) in f
        len = length(ω)
        if len == 1
            u = only(ω)
            push!(vars, u)
            lin[u] = get(lin, u, zero(T)) + c
        elseif len == 2
            u, v = ω
            push!(vars, u)
            push!(vars, v)
            quad_row_sum[u] = get(quad_row_sum, u, zero(T)) + c
            quad_row_sum[v] = get(quad_row_sum, v, zero(T)) + c
        end
    end

    return (vars, lin, quad_row_sum)
end

function coercive_field(f::AbstractPBF{V,T}, x::V) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "coercive_field is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    H = typeof(zero(T) / 4)
    lin_x = zero(T)
    quad_x = zero(T)

    for (ω, c) in f
        len = length(ω)
        if len == 1 && x in ω
            lin_x += c
        elseif len == 2 && x in ω
            quad_x += c
        end
    end

    return (2 * H(lin_x) + H(quad_x)) / 4
end

function coercive_fields(f::AbstractPBF{V,T}) where {V,T}
    vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :coercive_fields)
    H = typeof(zero(T) / 4)
    out = Dict{V,H}()
    sizehint!(out, length(vars))

    for u in sort!(collect(vars); lt = varlt)
        l_u = get(lin, u, zero(T))
        q_u = get(quad_row_sum, u, zero(T))
        out[u] = (2 * H(l_u) + H(q_u)) / 4
    end

    return out
end

function is_gauge_invariant(f::AbstractPBF{V,T}; atol::Real = 0.0)::Bool where {V,T}
    (atol >= 0 && !isnan(atol)) ||
        throw(ArgumentError("atol must be nonnegative; got $atol"))
    vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :is_gauge_invariant)
    H = typeof(zero(T) / 4)

    for u in vars
        l_u = get(lin, u, zero(T))
        q_u = get(quad_row_sum, u, zero(T))
        if iszero(atol) && T <: Union{Integer,Rational}
            iszero(2 * l_u + q_u) || return false
        else
            abs((2 * H(l_u) + H(q_u)) / 4) <= atol || return false
        end
    end

    return true
end

function gauge_invariant_qubo!(
    f::F;
    keep_constant::Bool = true,
) where {V,T,F<:AbstractPBF{V,T}}
    vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :gauge_invariant_qubo!)

    if T <: Integer
        for u in sort!(collect(keys(quad_row_sum)); lt = varlt)
            q_u = quad_row_sum[u]
            iseven(q_u) || throw(
                ArgumentError(
                    "cannot represent half-integer gauge-invariant linear coefficient -($q_u)/2 for variable $u in integer PBF type $F",
                ),
            )
        end
    end

    if !keep_constant
        f[nothing] = zero(T)
    end

    for u in keys(lin)
        if !haskey(quad_row_sum, u)
            f[u] = zero(T)
        end
    end

    for (u, q_u) in quad_row_sum
        f[u] = T <: Integer ? -div(q_u, 2) : convert(T, -q_u / 2)
    end

    return f
end

function gauge_invariant_qubo(
    f::AbstractPBF{V,T};
    keep_constant::Bool = true,
) where {V,T}
    return gauge_invariant_qubo!(copy(f); keep_constant)
end

function Base.convert(::Type{U}, f::AbstractPBF{V,T}) where {V,T,U<:Number}
    if isconstant(f)
        return convert(U, f[nothing])
    else
        error("Can't convert non-scalar pseudo-Boolean function to scalar type '$U'")
    end
end

function Base.show(io::IO, ::MIME"text/plain", f::AbstractPBF{V,T}) where {V,T}
    if isconstant(f)
        print(io, f[nothing])

        return nothing
    end

    terms = sort!(collect(f); by=first, lt=varlt)

    for (i, (ω, c)) in enumerate(terms)
        if i > 1
            if c < zero(T)
                print(io, " - ")
            else
                print(io, " + ")
            end
        else # i == 1
            if c < zero(T)
                print(io, "-")
            end
        end

        c_ = abs(c)

        if isempty(ω)
            print(io, c_)
        elseif isone(c_)
            join(io, varshow.(ω), " ")
        else
            join(io, [string(c_); varshow.(ω)], " ")
        end
    end

    return nothing
end

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

_coercive_accum_type(::Type{<:Integer}) = BigInt
_coercive_accum_type(::Type{<:Rational}) = Rational{BigInt}
_coercive_accum_type(::Type{<:AbstractFloat}) = BigFloat
_coercive_accum_type(::Type{T}) where {T} = typeof(zero(T) + zero(T))

function _with_coercive_precision(fn::Function, ::Type{T}) where {T}
    if T <: AbstractFloat && T !== BigFloat
        return setprecision(fn, BigFloat, 2112)
    elseif T === BigFloat
        return setprecision(fn, BigFloat, max(precision(BigFloat), 2112))
    else
        return fn()
    end
end

function _coercive_field_from_sums(::Type{H}, l_u::BigInt, q_u::BigInt) where {H}
    return convert(H, (2 * l_u + q_u) // 4)
end

function _coercive_field_from_sums(
    ::Type{H},
    l_u::Rational{BigInt},
    q_u::Rational{BigInt},
) where {H}
    return convert(H, (2 * l_u + q_u) / 4)
end

function _coercive_field_from_sums(::Type{H}, l_u, q_u) where {H}
    return convert(H, l_u / 2 + q_u / 4)
end

function _coercive_abs_le_atol(::Type{H}, l_u::BigInt, q_u::BigInt, atol::Real) where {H}
    res = 2 * l_u + q_u
    iszero(atol) && return iszero(res)
    isinf(atol) && return true
    return abs(res // 4) <= Rational{BigInt}(atol)
end

function _coercive_abs_le_atol(
    ::Type{H},
    l_u::Rational{BigInt},
    q_u::Rational{BigInt},
    atol::Real,
) where {H}
    res = 2 * l_u + q_u
    iszero(atol) && return iszero(res)
    isinf(atol) && return true
    return abs(res / 4) <= Rational{BigInt}(atol)
end

function _coercive_abs_le_atol(::Type{H}, l_u::BigFloat, q_u::BigFloat, atol::Real) where {H}
    h_big = l_u / 2 + q_u / 4
    isnan(h_big) && return false
    isinf(atol) && return isfinite(h_big) || isinf(h_big)
    return abs(h_big) <= BigFloat(atol)
end

function _coercive_abs_le_atol(::Type{H}, l_u, q_u, atol::Real) where {H}
    return abs(_coercive_field_from_sums(H, l_u, q_u)) <= atol
end

function _quadratic_linear_and_row_sums(f::AbstractPBF{V,T}, caller::Symbol) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "$caller is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    return _with_coercive_precision(T) do
        A = _coercive_accum_type(T)
        lin = Dict{V,A}()
        quad_row_sum = Dict{V,A}()
        vars = Set{V}()

        for (ω, c) in f
            len = length(ω)
            if len == 1
                u = only(ω)
                push!(vars, u)
                c_acc = convert(A, c)
                lin[u] = get(lin, u, zero(A)) + c_acc
            elseif len == 2
                u, v = ω
                push!(vars, u)
                push!(vars, v)
                c_acc = convert(A, c)
                quad_row_sum[u] = get(quad_row_sum, u, zero(A)) + c_acc
                quad_row_sum[v] = get(quad_row_sum, v, zero(A)) + c_acc
            end
        end

        return (vars, lin, quad_row_sum)
    end
end

function coercive_field(f::AbstractPBF{V,T}, x::V) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "coercive_field is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    return _with_coercive_precision(T) do
        H = typeof(zero(T) / 4)
        A = _coercive_accum_type(T)
        lin_x = zero(A)
        quad_x = zero(A)

        for (ω, c) in f
            len = length(ω)
            if len == 1 && x in ω
                lin_x += convert(A, c)
            elseif len == 2 && x in ω
                quad_x += convert(A, c)
            end
        end

        return _coercive_field_from_sums(H, lin_x, quad_x)
    end
end

function coercive_fields(f::AbstractPBF{V,T}) where {V,T}
    return _with_coercive_precision(T) do
        vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :coercive_fields)
        A = _coercive_accum_type(T)
        H = typeof(zero(T) / 4)
        out = Dict{V,H}()
        sizehint!(out, length(vars))

        for u in sort!(collect(vars); lt = varlt)
            l_u = get(lin, u, zero(A))
            q_u = get(quad_row_sum, u, zero(A))
            out[u] = _coercive_field_from_sums(H, l_u, q_u)
        end

        return out
    end
end

function is_gauge_invariant(f::AbstractPBF{V,T}; atol::Real = 0.0)::Bool where {V,T}
    (atol >= 0 && !isnan(atol)) ||
        throw(ArgumentError("atol must be nonnegative; got $atol"))
    return _with_coercive_precision(T) do
        vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :is_gauge_invariant)
        A = _coercive_accum_type(T)
        H = typeof(zero(T) / 4)

        for u in vars
            l_u = get(lin, u, zero(A))
            q_u = get(quad_row_sum, u, zero(A))
            _coercive_abs_le_atol(H, l_u, q_u, atol) || return false
        end

        return true
    end
end

function gauge_invariant_qubo!(
    f::F;
    keep_constant::Bool = true,
) where {V,T,F<:AbstractPBF{V,T}}
    vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :gauge_invariant_qubo!)
    target_lin = Dict{V,T}()
    sizehint!(target_lin, length(quad_row_sum))

    _with_coercive_precision(T) do
        for u in sort!(collect(keys(quad_row_sum)); lt = varlt)
            q_u = quad_row_sum[u]
            if T <: Integer
                iseven(q_u) || throw(
                    ArgumentError(
                        "cannot represent half-integer gauge-invariant linear coefficient -($q_u)/2 for variable $u in integer PBF type $F",
                    ),
                )
                c_big = -div(q_u, 2)
                if T !== BigInt && (c_big < BigInt(typemin(T)) || c_big > BigInt(typemax(T)))
                    throw(
                        ArgumentError(
                            "cannot represent gauge-invariant linear coefficient $c_big for variable $u in integer PBF type $F",
                        ),
                    )
                end
                target_lin[u] = convert(T, c_big)
            else
                target_lin[u] = convert(T, -(q_u / 2))
            end
        end
    end

    if !keep_constant
        f[nothing] = zero(T)
    end

    for u in keys(lin)
        if !haskey(target_lin, u)
            f[u] = zero(T)
        end
    end

    for (u, c_u) in target_lin
        f[u] = c_u
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

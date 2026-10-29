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

const _COERCIVE_CLUSTER_SPAN_LIMIT = 65536

struct _DyadicTerm
    m::BigInt
    e::Int
end

function _canonical_dyadic(m::BigInt, e::Int)
    iszero(m) && return nothing
    tz = trailing_zeros(m)
    return _DyadicTerm(m >> tz, e + tz)
end

function _dyadic_from_float(x::AbstractFloat, shift::Int = 0)
    iszero(x) && return nothing
    p = precision(x)
    ex = exponent(x)
    m_raw = BigInt(ldexp(x, p - 1 - ex))
    return _canonical_dyadic(m_raw, ex - (p - 1) + shift)
end

_dyadic_lsb(t::_DyadicTerm) = t.e
_dyadic_msb(t::_DyadicTerm) = t.e + ndigits(abs(t.m), base = 2) - 1

function _dyadic_add(a::_DyadicTerm, b::_DyadicTerm)
    if a.e >= b.e
        return _canonical_dyadic((a.m << (a.e - b.e)) + b.m, b.e)
    else
        return _canonical_dyadic(a.m + (b.m << (b.e - a.e)), a.e)
    end
end

struct _FloatTermAccum
    terms::Vector{_DyadicTerm}
    has_nan::Bool
    pos_inf::Bool
    neg_inf::Bool
end

_FloatTermAccum() = _FloatTermAccum(_DyadicTerm[], false, false, false)

function _push_scaled_float!(acc::_FloatTermAccum, c::AbstractFloat, shift::Int)
    if isnan(c)
        return _FloatTermAccum(acc.terms, true, acc.pos_inf, acc.neg_inf)
    elseif isinf(c)
        return _FloatTermAccum(
            acc.terms,
            acc.has_nan,
            acc.pos_inf || (c > 0),
            acc.neg_inf || (c < 0),
        )
    elseif iszero(c)
        return acc
    else
        dt = _dyadic_from_float(c, shift)
        dt !== nothing && push!(acc.terms, dt)
        return acc
    end
end

function _reduce_dyadic_terms(
    terms::Vector{_DyadicTerm},
    min_gap::Int = _COERCIVE_CLUSTER_SPAN_LIMIT,
)
    isempty(terms) && return _DyadicTerm[]

    by_e = Dict{Int,BigInt}()
    for t in terms
        by_e[t.e] = get(by_e, t.e, zero(BigInt)) + t.m
    end

    work = _DyadicTerm[]
    sizehint!(work, length(by_e))
    for (e, m) in by_e
        dt = _canonical_dyadic(m, e)
        dt !== nothing && push!(work, dt)
    end

    while length(work) >= 2
        sort!(work; by = t -> (_dyadic_msb(t), t.e), rev = true)
        merged_any = false
        for i = 1:(length(work) - 1)
            a = work[i]
            b = work[i + 1]
            if _dyadic_lsb(a) - _dyadic_msb(b) <= min_gap
                c = _dyadic_add(a, b)
                deleteat!(work, (i, i + 1))
                c !== nothing && push!(work, c)
                merged_any = true
                break
            end
        end
        merged_any || break
    end

    sort!(work; by = t -> (_dyadic_msb(t), t.e), rev = true)
    return work
end

function _exact_float_clusters(
    acc::_FloatTermAccum,
    min_gap::Int = _COERCIVE_CLUSTER_SPAN_LIMIT,
)
    if acc.has_nan || (acc.pos_inf && acc.neg_inf)
        return (:nan, _DyadicTerm[])
    elseif acc.pos_inf
        return (:pos_inf, _DyadicTerm[])
    elseif acc.neg_inf
        return (:neg_inf, _DyadicTerm[])
    elseif isempty(acc.terms)
        return (:finite, _DyadicTerm[])
    else
        return (:finite, _reduce_dyadic_terms(acc.terms, min_gap))
    end
end

function _eval_float_accum(::Type{H}, acc::_FloatTermAccum, ambient_bf_prec::Int) where {H}
    target_prec = H === BigFloat ? ambient_bf_prec : max(256, precision(H) + 64)
    min_gap = max(_COERCIVE_CLUSTER_SPAN_LIMIT, 2 * target_prec + 256)
    status, clusters = _exact_float_clusters(acc, min_gap)
    if status === :nan
        return H === BigFloat ? setprecision(() -> BigFloat(NaN), BigFloat, ambient_bf_prec) : convert(H, NaN)
    elseif status === :pos_inf
        return H === BigFloat ? setprecision(() -> BigFloat(Inf), BigFloat, ambient_bf_prec) : convert(H, Inf)
    elseif status === :neg_inf
        return H === BigFloat ? setprecision(() -> BigFloat(-Inf), BigFloat, ambient_bf_prec) : convert(H, -Inf)
    elseif isempty(clusters)
        return H === BigFloat ? setprecision(() -> zero(BigFloat), BigFloat, ambient_bf_prec) : zero(H)
    else
        c1 = clusters[1]
        c1_bits = ndigits(abs(c1.m), base = 2)
        work_prec = max(256, c1_bits, target_prec) + 64
        adjusted = setprecision(BigFloat, work_prec) do
            base = ldexp(BigFloat(c1.m), c1.e)
            if length(clusters) >= 2
                return clusters[2].m > 0 ? nextfloat(base) : prevfloat(base)
            else
                return base
            end
        end
        if H === BigFloat
            return setprecision(() -> BigFloat(adjusted), BigFloat, ambient_bf_prec)
        else
            return convert(H, adjusted)
        end
    end
end

function _float_accum_abs_le_atol(acc::_FloatTermAccum, atol::Real)
    status, clusters = _exact_float_clusters(acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    status === :nan && return false
    isinf(atol) && return true
    (status === :pos_inf || status === :neg_inf) && return false
    isempty(clusters) && return true
    iszero(atol) && return false

    s1 = sign(clusters[1].m)
    diff_terms = _DyadicTerm[]
    sizehint!(diff_terms, length(clusters) + 1)

    if atol isa Rational
        atol_rat = Rational{BigInt}(atol)
        p = numerator(atol_rat)
        q = denominator(atol_rat)
        for t in clusters
            dt = _canonical_dyadic(s1 * q * t.m, t.e)
            dt !== nothing && push!(diff_terms, dt)
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa Integer
        p = BigInt(atol)
        for t in clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa AbstractFloat
        for t in clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        dt_a = _dyadic_from_float(atol)
        dt_a !== nothing && push!(diff_terms, _DyadicTerm(-dt_a.m, dt_a.e))
    else
        return _float_accum_abs_le_atol(acc, Rational{BigInt}(atol))
    end

    diff_reduced = _reduce_dyadic_terms(diff_terms, _COERCIVE_CLUSTER_SPAN_LIMIT)
    return isempty(diff_reduced) || diff_reduced[1].m < 0
end

_coercive_accum_type(::Type{<:Integer}) = BigInt
_coercive_accum_type(::Type{<:Rational}) = Rational{BigInt}
_coercive_accum_type(::Type{T}) where {T} = typeof(zero(T) + zero(T))

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

function _coercive_abs_le_atol(::Type{H}, l_u, q_u, atol::Real) where {H}
    return abs(_coercive_field_from_sums(H, l_u, q_u)) <= atol
end

function _quadratic_float_field_accums(f::AbstractPBF{V,T}, caller::Symbol) where {V,T<:AbstractFloat}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "$caller is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    field_acc = Dict{V,_FloatTermAccum}()
    neg_half_quad_acc = Dict{V,_FloatTermAccum}()
    has_lin = Set{V}()
    vars = Set{V}()

    for (ω, c) in f
        len = length(ω)
        if len == 1
            u = only(ω)
            push!(vars, u)
            push!(has_lin, u)
            field_acc[u] = _push_scaled_float!(get(field_acc, u, _FloatTermAccum()), c, -1)
        elseif len == 2
            u, v = ω
            push!(vars, u)
            push!(vars, v)
            field_acc[u] = _push_scaled_float!(get(field_acc, u, _FloatTermAccum()), c, -2)
            field_acc[v] = _push_scaled_float!(get(field_acc, v, _FloatTermAccum()), c, -2)
            neg_half_quad_acc[u] =
                _push_scaled_float!(get(neg_half_quad_acc, u, _FloatTermAccum()), -c, -1)
            neg_half_quad_acc[v] =
                _push_scaled_float!(get(neg_half_quad_acc, v, _FloatTermAccum()), -c, -1)
        end
    end

    return (vars, has_lin, field_acc, neg_half_quad_acc)
end

function _quadratic_linear_and_row_sums(f::AbstractPBF{V,T}, caller::Symbol) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "$caller is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

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

function coercive_field(f::AbstractPBF{V,T}, x::V) where {V,T}
    deg = degree(f)
    deg <= 2 || throw(
        ArgumentError(
            "coercive_field is only defined for quadratic pseudo-Boolean functions (degree <= 2); got degree $deg",
        ),
    )

    H = typeof(zero(T) / 4)
    if T <: AbstractFloat
        ambient_prec = precision(BigFloat)
        acc = _FloatTermAccum()
        for (ω, c) in f
            len = length(ω)
            if len == 1 && x in ω
                acc = _push_scaled_float!(acc, c, -1)
            elseif len == 2 && x in ω
                acc = _push_scaled_float!(acc, c, -2)
            end
        end
        return _eval_float_accum(H, acc, ambient_prec)
    else
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
    H = typeof(zero(T) / 4)
    if T <: AbstractFloat
        ambient_prec = precision(BigFloat)
        vars, _, field_acc, _ = _quadratic_float_field_accums(f, :coercive_fields)
        out = Dict{V,H}()
        sizehint!(out, length(vars))
        for u in sort!(collect(vars); lt = varlt)
            acc = get(field_acc, u, _FloatTermAccum())
            out[u] = _eval_float_accum(H, acc, ambient_prec)
        end
        return out
    else
        vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :coercive_fields)
        A = _coercive_accum_type(T)
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
    if T <: AbstractFloat
        vars, _, field_acc, _ = _quadratic_float_field_accums(f, :is_gauge_invariant)
        for u in vars
            acc = get(field_acc, u, _FloatTermAccum())
            _float_accum_abs_le_atol(acc, atol) || return false
        end
        return true
    else
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
    if T <: AbstractFloat
        ambient_prec = precision(BigFloat)
        _, has_lin, _, neg_half_quad_acc =
            _quadratic_float_field_accums(f, :gauge_invariant_qubo!)
        target_lin = Dict{V,T}()
        sizehint!(target_lin, length(neg_half_quad_acc))
        for u in sort!(collect(keys(neg_half_quad_acc)); lt = varlt)
            target_lin[u] = _eval_float_accum(T, neg_half_quad_acc[u], ambient_prec)
        end

        if !keep_constant
            f[nothing] = zero(T)
        end

        for u in has_lin
            if !haskey(target_lin, u)
                f[u] = zero(T)
            end
        end

        for (u, c_u) in target_lin
            f[u] = c_u
        end

        return f
    end

    vars, lin, quad_row_sum = _quadratic_linear_and_row_sums(f, :gauge_invariant_qubo!)
    target_lin = Dict{V,T}()
    sizehint!(target_lin, length(quad_row_sum))

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

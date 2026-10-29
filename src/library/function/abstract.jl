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

struct _FloatTermAccum
    terms::Vector{BigFloat}
    has_nan::Bool
    pos_inf::Bool
    neg_inf::Bool
end

_FloatTermAccum() = _FloatTermAccum(BigFloat[], false, false, false)

function _push_scaled_float!(acc::_FloatTermAccum, c::Real, shift::Int)
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
        prec = max(64, precision(c) + 16)
        bf = setprecision(BigFloat, prec) do
            ldexp(BigFloat(c), shift)
        end
        push!(acc.terms, bf)
        return acc
    end
end

function _exact_float_clusters(acc::_FloatTermAccum, min_merge_span::Int = _COERCIVE_CLUSTER_SPAN_LIMIT)
    if acc.has_nan || (acc.pos_inf && acc.neg_inf)
        return (:nan, BigFloat[])
    elseif acc.pos_inf
        return (:pos_inf, BigFloat[])
    elseif acc.neg_inf
        return (:neg_inf, BigFloat[])
    elseif isempty(acc.terms)
        return (:finite, BigFloat[])
    end

    sorted = sort(acc.terms; by = exponent, rev = true)
    raw_clusters = BigFloat[]
    n = length(sorted)
    i = 1
    while i <= n
        j = i
        cluster_msb = exponent(sorted[i])
        cluster_lsb = exponent(sorted[i]) - precision(sorted[i])
        while j < n
            next_msb = exponent(sorted[j + 1])
            next_lsb = next_msb - precision(sorted[j + 1])
            if cluster_msb - next_lsb <= min_merge_span
                cluster_msb = max(cluster_msb, next_msb)
                cluster_lsb = min(cluster_lsb, next_lsb)
                j += 1
            else
                break
            end
        end
        carry_bits = ceil(Int, log2(max(2, j - i + 2))) + 32
        work_prec = max(256, cluster_msb - cluster_lsb + carry_bits)
        c_sum = setprecision(BigFloat, work_prec) do
            s = zero(BigFloat)
            for k = i:j
                s += sorted[k]
            end
            return s
        end
        if !iszero(c_sum)
            push!(raw_clusters, c_sum)
        end
        i = j + 1
    end

    isempty(raw_clusters) && return (:finite, BigFloat[])

    # Second pass: merge adjacent non-zero clusters whose bit span is within min_merge_span
    merged = BigFloat[raw_clusters[1]]
    for k = 2:length(raw_clusters)
        prev = merged[end]
        curr = raw_clusters[k]
        msb = max(exponent(prev), exponent(curr))
        lsb = min(exponent(prev) - precision(prev), exponent(curr) - precision(curr))
        if msb - lsb <= min_merge_span
            work_prec = max(256, msb - lsb + 64)
            s = setprecision(BigFloat, work_prec) do
                BigFloat(prev) + BigFloat(curr)
            end
            if iszero(s)
                pop!(merged)
            else
                merged[end] = s
            end
        else
            push!(merged, curr)
        end
    end

    return (:finite, merged)
end

function _eval_float_accum(::Type{H}, acc::_FloatTermAccum, ambient_bf_prec::Int) where {H}
    target_prec = H === BigFloat ? ambient_bf_prec : max(256, precision(H) + 64)
    merge_span = max(_COERCIVE_CLUSTER_SPAN_LIMIT, 2 * target_prec + 256)
    status, clusters = _exact_float_clusters(acc, merge_span)
    if status === :nan
        return H === BigFloat ? setprecision(() -> BigFloat(NaN), BigFloat, ambient_bf_prec) : convert(H, NaN)
    elseif status === :pos_inf
        return H === BigFloat ? setprecision(() -> BigFloat(Inf), BigFloat, ambient_bf_prec) : convert(H, Inf)
    elseif status === :neg_inf
        return H === BigFloat ? setprecision(() -> BigFloat(-Inf), BigFloat, ambient_bf_prec) : convert(H, -Inf)
    elseif isempty(clusters)
        return H === BigFloat ? setprecision(() -> zero(BigFloat), BigFloat, ambient_bf_prec) : zero(H)
    elseif length(clusters) == 1
        c1 = clusters[1]
        if H === BigFloat
            return setprecision(() -> BigFloat(c1), BigFloat, ambient_bf_prec)
        else
            return convert(H, c1)
        end
    else
        c1 = clusters[1]
        c2 = clusters[2]
        sticky_prec = max(precision(c1), target_prec) + 64
        adjusted = setprecision(BigFloat, sticky_prec) do
            base = BigFloat(c1)
            return c2 > 0 ? nextfloat(base) : prevfloat(base)
        end
        if H === BigFloat
            return setprecision(() -> BigFloat(adjusted), BigFloat, ambient_bf_prec)
        else
            return convert(H, adjusted)
        end
    end
end

function _float_accum_abs_le_atol(acc::_FloatTermAccum, atol::Real)
    status, clusters = _exact_float_clusters(acc)
    status === :nan && return false
    isinf(atol) && return true
    (status === :pos_inf || status === :neg_inf) && return false
    isempty(clusters) && return true
    iszero(atol) && return false

    if atol isa Rational
        atol_rat = Rational{BigInt}(atol)
        p = numerator(atol_rat)
        q = denominator(atol_rat)
        p_bits = ndigits(p, base = 2)
        q_bits = ndigits(q, base = 2)
        # Compare |q * sum(clusters)| <= p exactly
        scaled_acc = _FloatTermAccum()
        for c in clusters
            w_prec = max(256, precision(c) + q_bits + 64)
            qc = setprecision(BigFloat, w_prec) do
                BigFloat(c) * BigFloat(q)
            end
            push!(scaled_acc.terms, qc)
        end
        _, q_clusters = _exact_float_clusters(
            scaled_acc,
            max(_COERCIVE_CLUSTER_SPAN_LIMIT, p_bits + q_bits + 256),
        )
        isempty(q_clusters) && return true
        c1 = q_clusters[1]
        s1 = sign(c1)
        abs_c1_exp = exponent(c1)
        if abs_c1_exp + 2 < p_bits
            return true
        elseif abs_c1_exp - 2 > p_bits
            return false
        end
        cmp_prec = max(256, precision(c1) + p_bits + 64)
        return setprecision(BigFloat, cmp_prec) do
            abs_c1 = abs(BigFloat(c1))
            p_bf = BigFloat(p)
            if abs_c1 < p_bf
                return true
            elseif abs_c1 > p_bf
                return false
            else
                return length(q_clusters) == 1 || sign(q_clusters[2]) != s1
            end
        end
    elseif atol isa Integer
        p = BigInt(atol)
        p_bits = ndigits(p, base = 2)
        _, m_clusters = _exact_float_clusters(
            acc,
            max(_COERCIVE_CLUSTER_SPAN_LIMIT, p_bits + 256),
        )
        isempty(m_clusters) && return true
        c1 = m_clusters[1]
        s1 = sign(c1)
        abs_c1_exp = exponent(c1)
        if abs_c1_exp + 2 < p_bits
            return true
        elseif abs_c1_exp - 2 > p_bits
            return false
        end
        cmp_prec = max(256, precision(c1) + p_bits + 64)
        return setprecision(BigFloat, cmp_prec) do
            abs_c1 = abs(BigFloat(c1))
            p_bf = BigFloat(p)
            if abs_c1 < p_bf
                return true
            elseif abs_c1 > p_bf
                return false
            else
                return length(m_clusters) == 1 || sign(m_clusters[2]) != s1
            end
        end
    else
        atol_prec = atol isa AbstractFloat ? precision(atol) : 256
        _, m_clusters = _exact_float_clusters(
            acc,
            max(_COERCIVE_CLUSTER_SPAN_LIMIT, atol_prec + 256),
        )
        isempty(m_clusters) && return true
        c1 = m_clusters[1]
        s1 = sign(c1)
        cmp_prec = max(256, precision(c1) + atol_prec + 64)
        return setprecision(BigFloat, cmp_prec) do
            abs_c1 = abs(BigFloat(c1))
            a_bf = BigFloat(atol)
            if abs_c1 < a_bf
                return true
            elseif abs_c1 > a_bf
                return false
            else
                return length(m_clusters) == 1 || sign(m_clusters[2]) != s1
            end
        end
    end
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

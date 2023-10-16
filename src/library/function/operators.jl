# Mapping: 'map', 'map!'
function Base.map(φ::Function, f::PBF{V,Tf,S}) where {V,Tf,S}
    Ω = keys(f)
    c = map(ω -> φ(f[ω]), Ω)
    T = promote_type(Tf, eltype(c))
    g = zero(PBF{V,T,S})

    for (i, ω) in enumerate(Ω)
        g[ω] = c[i]
    end

    return g
end

function Base.map!(φ::Function, f::F) where {V,T,F<:AbstractPBF{V,T}}
    for (ω, c) in f
        f[ω] = φ(c)
    end

    return f
end

function Base.map!(
    φ::Function,
    f::Ff,
    g::Fg,
) where {V,Tf,Tg,Ff<:AbstractPBF{V,Tf},Fg<:AbstractPBF{V,Tg}}
    sizehint!(empty!(f), length(g))

    for (ω, c) in g
        f[ω] = φ(c)
    end

    return f
end

# Arithmetic: '+'
function Base.:(+)(f::PBF{V,Tf,Sf}, g::PBF{V,Tg,Sg}) where {V,Tf,Tg,Sf,Sg}
    F = promote_type(PBF{V,Tf,Sf}, PBF{V,Tg,Sg})
    Ω = union(keys(f), keys(g))
    h = sizehint!(zero(F), length(Ω))

    for ω in Ω
        h[ω] = f[ω] + g[ω]
    end

    return h
end

function Base.:(+)(f::PBF{V,Tf,S}, β::Tc) where {V,Tf,Tc,S}
    T = promote_type(Tf, Tc)
    g = copy!(zero(PBF{V,T,S}), f)

    g[nothing] += β

    return g
end

function Base.:(+)(β::Any, f::AbstractPBF)
    return +(f, β)
end

# Arithmetic: '-'
function Base.:(-)(f::PBF{V,Tf,Sf}, g::PBF{V,Tg,Sg}) where {V,Tf,Tg,Sf,Sg}
    F = promote_type(PBF{V,Tf,Sf}, PBF{V,Tg,Sg})
    Ω = union(keys(f), keys(g))
    h = sizehint!(zero(F), length(Ω))

    for ω in Ω
        h[ω] = f[ω] - g[ω]
    end

    return h
end

function Base.:(-)(f::F) where {V,T,F<:AbstractPBF{V,T}}
    return map!(c -> -c, zero(F), f)
end

function Base.:(-)(f::PBF{V,Tf,S}, β::Tc) where {V,Tf,Tc,S}
    T = promote_type(Tf, Tc)
    g = copy!(zero(PBF{V,T,S}), f)

    g[nothing] -= β

    return g
end

function Base.:(-)(β::Tc, f::PBF{V,Tf,S}) where {V,Tf,Tc,S}
    T = promote_type(Tf, Tc)
    g = zero(PBF{V,T,S})

    map!(c -> -c, g, f)

    g[nothing] += β

    return g
end

# Arithmetic: '*'
function Base.:(*)(f::PBF{V,Tf,Sf}, g::PBF{V,Tg,Sg}) where {V,Tf,Tg,Sf,Sg}
    F = promote_type(PBF{V,Tf,Sf}, PBF{V,Tg,Sg})
    h = zero(F)
    m = length(f)
    n = length(g)

    if iszero(f) || iszero(g) # T(n) = O(1)
        return h
    elseif f === g # T(n) = O(n) + O(n^2 / 2)
        k = collect(f)

        sizehint!(h, n^2 ÷ 2)

        for i = 1:n
            ωi, ci = k[i]

            h[ωi] += ci * ci

            for j = (i+1):n
                ωj, cj = k[j]

                h[ωi×ωj] += 2 * ci * cj
            end
        end

        return h
    else # T(n) = O(m n)
        sizehint!(h, m * n)

        for (ωᵢ, cᵢ) in f, (ωⱼ, cⱼ) in g
            h[ωᵢ×ωⱼ] += cᵢ * cⱼ
        end

        return h
    end
end

function Base.:(*)(f::PBF{V,Tf,S}, α::Tc) where {V,Tf,Tc,S}
    T = promote_type(Tf, Tc)
    g = zero(PBF{V,T,S})

    if !iszero(α)
        map!(c -> c * α, g, f)
    end

    return g
end

function Base.:(*)(α::Any, f::AbstractPBF)
    return *(f, α)
end

# Arithmetic: '/'
function Base.:(/)(f::PBF{V,Tf,S}, α::Tc) where {V,Tf,Tc,S}
    if iszero(α)
        throw(DivideError())
    end

    T = promote_type(Tf, Tc)
    g = zero(PBF{V,T,S})

    map!(c -> c / α, g, f)

    return g
end

# Arithmetic: '^'
function Base.:(^)(f::F, n::Integer) where {V,T,F<:AbstractPBF{V,T}}
    if n < 0
        throw(DivideError())
    elseif n == 0
        return one(F)
    elseif n == 1
        return copy(f)
    elseif n == 2
        return f * f
    else
        g = f * f

        if iseven(n)
            return g^(n ÷ 2)
        else
            return g^(n ÷ 2) * f
        end
    end
end

# Arithmetic: Evaluation
function (f::AbstractPBF{V,T})(x::Dict{V,U}) where {V,T,U<:Integer}
    g = zero(f)

    for (ω, c) in f
        η = Set{V}()

        for j in ω
            if haskey(x, j)
                if iszero(x[j])
                    c = zero(T)
                    break
                end
            else
                push!(η, j)
            end
        end

        if !iszero(c)
            g[η] += c
        end
    end

    return g
end

function (f::AbstractPBF{V,T})(η::Set{V}) where {V,T}
    return sum(c for (ω, c) in f if ω ⊆ η; init = zero(f))
end

function (f::AbstractPBF{V})(ps::Pair{V,U}...) where {V,U<:Integer}
    return f(Dict{V,U}(ps...))
end


# Comparsion: '=='
function Base.:(==)(f::AbstractPBF{V,Tf}, g::AbstractPBF{V,Tg}) where {V,Tf,Tg}
    return length(f) == length(g) && all(ω -> g[ω] == f[ω], keys(f))
end

# Comparison: '≈'
function Base.isapprox(f::AbstractPBF{V,Tf}, g::AbstractPBF{V,Tg}; kw...) where {V,Tf,Tg}
    return all(ω -> isapprox(g[ω], f[ω]; kw...), union(keys(f), keys(g)))
end

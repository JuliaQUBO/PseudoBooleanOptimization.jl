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
    return sum((c < zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f)
end

function upperbound(f::F) where {V,T,F<:AbstractPBF{V,T}}
    return sum((c > zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f)
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

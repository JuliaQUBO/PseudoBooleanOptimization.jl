function benchmark_constructors!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["constructors"] = BenchmarkGroup()

    return nothing
end
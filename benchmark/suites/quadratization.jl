function benchmark_quadratization!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["quadratization"] = BenchmarkGroup()
    suite["quadratization"]["automatic"] = BenchmarkGroup()
    suite["quadratization"]["automatic"]["small"] = @benchmarkable(
        PBO.quadratize(f, PBO.Quadratization{PBO.INFER}());
        setup = begin
            f = PBO.k_regular_k_xorsat(Random.GLOBAL_RNG, $F, 10, 3; quad = nothing)
        end
    )
    suite["quadratization"]["automatic"]["large"] = @benchmarkable(
        PBO.quadratize(f, PBO.Quadratization{PBO.INFER}());
        setup = begin
            f = PBO.k_regular_k_xorsat(Random.GLOBAL_RNG, $F, 100, 3; quad = nothing)
        end
    )

    return nothing
end
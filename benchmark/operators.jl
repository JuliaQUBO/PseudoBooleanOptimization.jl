function benchmark_operators!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"] = BenchmarkGroup()

    benchmark_add!(suite, F)
    benchmark_sub!(suite, F)
    benchmark_mul!(suite, F)

    return nothing
end

function benchmark_add!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["+"] = BenchmarkGroup()
    suite["operators"]["+"]["small"] = @benchmarkable(
        f + g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["+"]["large"] = @benchmarkable(
        f + g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
        end
    )

    return nothing
end

function benchmark_mut_add!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["+!"] = BenchmarkGroup()
    suite["operators"]["+!"]["small"] = @benchmarkable(
        f += g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["+!"]["large"] = @benchmarkable(
        f += g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
        end
    )

    return nothing
end

function benchmark_sub!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["-"] = BenchmarkGroup()
    suite["operators"]["-"]["small"] = @benchmarkable(
        f - g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["-"]["large"] = @benchmarkable(
        f - g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
        end
    )

    return nothing
end

function benchmark_mut_sub!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["-!"] = BenchmarkGroup()
    suite["operators"]["-!"]["small"] = @benchmarkable(
        f -= g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["-!"]["large"] = @benchmarkable(
        f -= g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
        end
    )

    return nothing
end

function benchmark_mul!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["*"] = BenchmarkGroup()
    suite["operators"]["*"]["small"] = @benchmarkable(
        f * g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["*"]["large"] = @benchmarkable(
        f * g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 32)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 32)
        end
    )

    return nothing
end

function benchmark_mut_mul!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractFunction{V,T}}
    suite["operators"]["*!"] = BenchmarkGroup()
    suite["operators"]["*!"]["small"] = @benchmarkable(
        f *= g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
        end
    )
    suite["operators"]["*!"]["large"] = @benchmarkable(
        f *= g;
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 32)
            g = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 32)
        end
    )

    return nothing
end

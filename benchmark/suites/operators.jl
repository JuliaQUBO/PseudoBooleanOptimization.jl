function benchmark_operators!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
    suite["operators"] = BenchmarkGroup()

    benchmark_add!(suite, F)
    benchmark_sub!(suite, F)
    benchmark_mul!(suite, F)

    benchmark_dict_evaluation!(suite, F)
    benchmark_set_evaluation!(suite, F)

    return nothing
end

function benchmark_add!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
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

function benchmark_sub!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
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

function benchmark_mul!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
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

function benchmark_dict_evaluation!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
    suite["operators"]["dict-evaluation"] = BenchmarkGroup()
    suite["operators"]["dict-evaluation"]["small"] = @benchmarkable(
        f(x);
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            x = Dict{Int,Int}(i => rand((0, 1)) for i = 1:10)
        end
    )
    suite["operators"]["dict-evaluation"]["large"] = @benchmarkable(
        f(x);
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            x = Dict{Int,Int}(i => rand((0, 1)) for i = 1:100)
        end
    )

    return nothing
end

function benchmark_set_evaluation!(suite, ::Type{F}) where {V,T,F<:PBO.AbstractPBF{V,T}}
    suite["operators"]["set-evaluation"] = BenchmarkGroup()
    suite["operators"]["set-evaluation"]["small"] = @benchmarkable(
        f(x);
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 10)
            x = Set{Int}(i for i = 1:10 if rand(Bool))
        end
    )
    suite["operators"]["set-evaluation"]["large"] = @benchmarkable(
        f(x);
        setup = begin
            f = PBO.sherrington_kirkpatrick(Random.GLOBAL_RNG, $F, 100)
            x = Set{Int}(i for i = 1:100 if rand(Bool))
        end
    )

    return nothing
end

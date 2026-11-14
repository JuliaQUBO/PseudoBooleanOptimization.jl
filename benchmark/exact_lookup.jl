# Run baseline and candidate with the same Julia/project/depot and one thread:
# julia --startup-file=no --project=ENV benchmark/exact_lookup.jl OUT.toml
using PseudoBooleanOptimization
using TOML
using LinearAlgebra
const PBO = PseudoBooleanOptimization

function lookup_batch!(output, f, terms)
    for i in eachindex(output)
        output[i] = f[terms[i]]
    end
    return last(output)
end

function measure!(rows, label, action; repeats = 5)
    action(); action() # two symmetric warmups, included in the trial allowance
    for repetition in 1:repeats
        GC.gc()
        stats = @timed action()
        push!(rows, Dict("operation" => label, "repetition" => repetition,
            "seconds" => stats.time, "bytes" => stats.bytes,
            "allocations" => Base.gc_alloc_count(stats.gcstats),
            "gc_seconds" => stats.gctime, "result" => string(stats.value)))
    end
end

function main(output)
    rows = Dict{String,Any}[]
    construction = @timed begin
        F = PBO.TermDictPBF{Int,Rational{BigInt}}
        residual = F((i => BigInt(i % 7 + 1)//BigInt(3) for i in 1:100))
        f = residual^2
        g = F(reverse(collect(f)))
        unequal = copy(g)
        unequal[1] += 1
        (f, g, unequal)
    end
    f, g, unequal = construction.value
    keys_f = collect(keys(f))
    hit_terms = [keys_f[mod1(i, length(keys_f))] for i in 1:10000]
    miss_terms = fill(PBO.term_head(typeof(f), 1000), 10000)
    output_values = Vector{Rational{BigInt}}(undef, 10000)
    measure!(rows, "10000 existing Rational{BigInt} coefficients", () -> lookup_batch!(output_values, f, hit_terms))
    measure!(rows, "10000 missing Rational{BigInt} coefficients", () -> lookup_batch!(output_values, f, miss_terms))
    measure!(rows, "equal 5050-term rational polynomials", () -> f == g)
    measure!(rows, "unequal 5050-term rational polynomials", () -> f == unequal)
    open(output, "w") do io
        TOML.print(io, Dict("julia" => string(VERSION), "source" => pathof(PBO),
            "threads" => Threads.nthreads(), "blas_threads" => BLAS.get_num_threads(),
            "warmups_per_operation" => 2, "repetitions" => 5,
            "terms" => length(f), "fixture_construction_seconds" => construction.time,
            "fixture_construction_bytes" => construction.bytes, "samples" => rows))
    end
end

main(only(ARGS))

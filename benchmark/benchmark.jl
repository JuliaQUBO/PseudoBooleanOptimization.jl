import Pkg

if "--main" ∈ ARGS
    Pkg.add(; name="PseudoBooleanOptimization", rev="main")
end

if "--dev" ∈ ARGS
    Pkg.develop(; path=joinpath(@__DIR__, ".."))
end

using Random
using BenchmarkTools
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

Random.seed!(0)

const SUITE = BenchmarkGroup()

include("suites/constructors.jl")

benchmark_constructors!(SUITE, PBO.PBF{Int,Float64})

include("suites/operators.jl")

benchmark_operators!(SUITE, PBO.PBF{Int,Float64})

include("suites/quadratization.jl")

benchmark_quadratization!(SUITE, PBO.PBF{Int,Float64})

function benchmark_main(suite)
    data_path = joinpath(@__DIR__, "data")
    
    mkpath(data_path) # Create if not exists

    params_path  = joinpath(data_path, "params.json")
    results_path = joinpath(data_path, "results-main.json")

    @info "Generating parameters @ main"
    BenchmarkTools.tune!(suite)
    BenchmarkTools.save(params_path, params(suite))

    @info "Running benchmark @ main"
    results = BenchmarkTools.run(suite)

    BenchmarkTools.save(results_path, results)

    return nothing
end

function benchmark_dev(suite)
    data_path = joinpath(@__DIR__, "data")
    
    mkpath(data_path) # Create if not exists

    params_path  = joinpath(data_path, "params.json")
    results_path = joinpath(data_path, "results-dev.json")

    @info "Loading parameters @ dev"
    loadparams!(suite, first(BenchmarkTools.load(params_path)), :evals, :samples)

    @info "Running benchmarks @ dev"
    results = BenchmarkTools.run(suite)

    BenchmarkTools.save(results_path, results)

    return nothing
end

if "--run" ∈ ARGS
    if "--main" ∈ ARGS
        benchmark_main(SUITE)
    end
    
    if "--dev" ∈ ARGS
        benchmark_dev(SUITE)
    end
end

using BenchmarkTools
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

const SUITE = BenchmarkGroup()

f = PBO.PBF{Symbol,Float64}([
    :x => 3.0,
    :y => 3.0,
    :z => 2.0,
    :w => 1.0,
])

g = PBO.PBF{Symbol,Float64}([
    :x => 3.0,
    :y => -3.0,
    :z => 2.0,
    :w => -1.0,
])

seed!(0)

SUITE["operators"] = BenchmarkGroup()
SUITE["operators"]["+"] = @benchmarkable(
    f + g;
    setup = begin
        f = rand(PBF)
        g = rand(PBF)
    end
)

BenchmarkTools.tune!(SUITE)

results = BenchmarkTools.run(SUITE)

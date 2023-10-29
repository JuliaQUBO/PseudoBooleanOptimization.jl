using Pkg
using Pkg.Types: PkgError
using Test
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

# Test assets, i.e., helper functions, test examples and data mockups
include("assets/assets.jl")

# Unit tests
include("unit/unit.jl")

# Integration tests
include("integration/integration.jl")

function run_foreign_tests()::Bool
    return "--run-foreign-tests" ∈ ARGS || get_bool_env("RUN_FOREIGN_TESTS", false)
end

function main(; _run_foreign_tests::Bool = run_foreign_tests())
    @testset "♠ PseudoBooleanOptimization.jl $(PBO.__VERSION__) Test Suite ♠" verbose = true begin
        unit_tests()
        integration_tests(; _run_foreign_tests)
    end

    return nothing
end

main() # Here we go!

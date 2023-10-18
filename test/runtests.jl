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

function main(; run_itegration_tests::Bool = get_bool_env("PBO_INTEGRATION_TESTS", false))
    @testset "♠ PseudoBooleanOptimization.jl $(PBO.__VERSION__) Test Suite ♠" verbose = true begin
        unit_tests()

        if run_itegration_tests
            integration_tests()
        end
    end

    return nothing
end

main() # Here we go!

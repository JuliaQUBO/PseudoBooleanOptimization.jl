using Test
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

# Test assets, i.e., test examples and mockups
include("assets/assets.jl")

# Unit tests
include("unit/unit.jl")

function main()
    test_unit()
end

main() # Here we go!

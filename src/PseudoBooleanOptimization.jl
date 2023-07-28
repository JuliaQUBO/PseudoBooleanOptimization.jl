module PseudoBooleanOptimization

using Random
using LinearAlgebra
using MutableArithmetics
const MA = MutableArithmetics

include("library.jl")
include("interface.jl")
include("abstract.jl")

include("function/term.jl")
include("function/dict/function.jl")
# include("function/vector/function.jl")

# This selects the implementation onwards
const PBF{V,T} = DictFunction{V,T}

include("print.jl")
include("quadratization.jl")

# Synthetic PBF generation
include("synthesis/wishart.jl")
include("synthesis/regular_xorsat.jl")
include("synthesis/sherrington_kirkpatrick.jl")
include("synthesis/not_all_equal_3sat.jl")

end # module PseudoBooleanOptimization

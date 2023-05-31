module PseudoBooleanOptimization

using Random
using LinearAlgebra

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

# include("synthesis.jl")

end # module PseudoBooleanOptimization

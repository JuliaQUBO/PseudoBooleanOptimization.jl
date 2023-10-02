module PseudoBooleanOptimization

using Random
using LinearAlgebra
using MutableArithmetics
const MA = MutableArithmetics

# Interface Definition
include("interface/variable.jl")
include("interface/function.jl")
include("interface/quadratization.jl")

# Utility Functions
include("library/mod2linsolve.jl")
include("library/relaxedgcd.jl")
include("library/sortedmerge.jl")

include("library/variable/varlt.jl")
include("library/variable/vargen.jl")
include("library/variable/varmap.jl")
include("library/variable/varmul.jl")
include("library/variable/varshow.jl")

include("library/function/abstract.jl")
include("library/function/function.jl")
include("library/function/operators.jl")
include("library/function/setdict/setdict.jl")

include("library/quadratization/abstract.jl")
include("library/quadratization/ntr_kzfd.jl")
include("library/quadratization/ptr_bg.jl")

# Synthetic PBF generation
include("library/synthesis/wishart.jl")
include("library/synthesis/regular_xorsat.jl")
include("library/synthesis/sherrington_kirkpatrick.jl")
include("library/synthesis/not_all_equal_3sat.jl")

end # module PseudoBooleanOptimization

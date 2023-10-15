module PseudoBooleanOptimization

const PBO = PseudoBooleanOptimization

using Random
using LinearAlgebra
using MutableArithmetics
const MA = MutableArithmetics

# Versioning
using TOML
const __PROJECT__ = abspath(dirname(pathof(PBO)), "..")
const __VERSION__ = VersionNumber(
    getindex(TOML.parsefile(joinpath(__PROJECT__, "Project.toml")), "version"),
)

# Interface Definition
include("interface/variables.jl")
include("interface/function.jl")
include("interface/quadratization.jl")

# Utility Functions
include("library/subscript.jl")
include("library/mod2linsolve.jl")
include("library/relaxedgcd.jl")
include("library/sortedmerge.jl")

include("library/variables/varlt.jl")
include("library/variables/vargen.jl")
include("library/variables/varmap.jl")
include("library/variables/varmul.jl")
include("library/variables/varshow.jl")

include("library/function/abstract.jl")
include("library/function/function.jl")
include("library/function/operators.jl")
include("library/function/setdict/setdict.jl")
include("library/function/default.jl")

include("library/quadratization/abstract.jl")
include("library/quadratization/ntr_kzfd.jl")
include("library/quadratization/ptr_bg.jl")

# Synthetic PBF generation
include("library/synthesis/wishart.jl")
include("library/synthesis/regular_xorsat.jl")
include("library/synthesis/sherrington_kirkpatrick.jl")
include("library/synthesis/not_all_equal_3sat.jl")

end # module PseudoBooleanOptimization

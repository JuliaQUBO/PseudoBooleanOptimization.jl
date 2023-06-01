using Documenter
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(PseudoBooleanOptimization, :DocTestSetup, :(using PseudoBooleanOptimization); recursive = true)

makedocs(;
    modules = [PseudoBooleanOptimization],
    doctest = true,
    clean = true,
    format = Documenter.HTML(
        assets = ["assets/extra_styles.css", "assets/favicon.ico"],
        mathengine = Documenter.KaTeX(),
        sidebar_sitename = false,
    ),
    sitename = "PseudoBooleanOptimization.jl",
    authors = "Pedro Maciel Xavier",
    pages = [
        "Home"           => "index.md",
        "Quadratization" => "quadratization.md"
    ],
    workdir = @__DIR__,
)

if "--skip-deploy" ∈ ARGS
    @warn "Skipping deployment"
else
    deploydocs(repo = raw"github.com/pedromxavier/PseudoBooleanOptimization.jl.git", push_preview = true)
end

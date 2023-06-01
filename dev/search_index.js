var documenterSearchIndex = {"docs":
[{"location":"quadratization/#Quadratization","page":"Quadratization","title":"Quadratization","text":"","category":"section"},{"location":"quadratization/","page":"Quadratization","title":"Quadratization","text":"PBO.quadratize\nPBO.quadratize!","category":"page"},{"location":"quadratization/#PseudoBooleanOptimization.quadratize","page":"Quadratization","title":"PseudoBooleanOptimization.quadratize","text":"quadratize(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}\n\nQuadratizes a given PBF, i.e., applies a mapping mathcalQ  mathscrF^k to mathscrF^2, where mathcalQ is the quadratization method.\n\nAuxiliary variables\n\nThe aux function is expected to produce auxiliary variables with the following signatures:\n\naux()::V where {V}\n\nCreates and returns a single variable.\n\naux(n::Integer)::Vector{V} where {V}\n\nCreates and returns a vector with n variables.\n\nquadratize(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}\n\nWhen aux is not specified, uses auxgen to generate variables.\n\n\n\n\n\n","category":"function"},{"location":"quadratization/#PseudoBooleanOptimization.quadratize!","page":"Quadratization","title":"PseudoBooleanOptimization.quadratize!","text":"quadratize!(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}\nquadratize!(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}\n\nIn-place version of quadratize.\n\n\n\n\n\n","category":"function"},{"location":"quadratization/","page":"Quadratization","title":"Quadratization","text":"PBO.auxgen","category":"page"},{"location":"quadratization/#PseudoBooleanOptimization.auxgen","page":"Quadratization","title":"PseudoBooleanOptimization.auxgen","text":"auxgen(::AbstractFunction{V,T}; name::AbstractString = \"aux\") where {V<:AbstractString,T}\n\nCreates a function that, when called multiple times, returns the strings \"aux_1\", \"aux_2\", ... and so on.\n\nauxgen(::AbstractFunction{Symbol,T}; name::Symbol = :aux) where {T}\n\nCreates a function that, when called multiple times, returns the symbols :aux_1, :aux_2, ... and so on.\n\nauxgen(::AbstractFunction{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}\n\nCreates a function that, when called multiple times, returns the integers -1, -2, ... and so on.\n\n\n\n\n\n","category":"function"},{"location":"quadratization/#Methods","page":"Quadratization","title":"Methods","text":"","category":"section"},{"location":"quadratization/","page":"Quadratization","title":"Quadratization","text":"PBO.NTR_KZFD\nPBO.PTR_BG\nPBO.DEFAULT","category":"page"},{"location":"quadratization/#PseudoBooleanOptimization.NTR_KZFD","page":"Quadratization","title":"PseudoBooleanOptimization.NTR_KZFD","text":"Quadratization{NTR_KZFD}(stable::Bool = false)\n\nNegative term reduction NTR-KZFD (Kolmogorov & Zabih, 2004; Freedman & Drineas, 2005)\n\nLet f(mathbfx) = -x_1 x_2 dots x_k.\n\nmathcalQleftlbracefrightrbrace(mathbfx z) = (k - 1) z - sum_i = 1^k x_i z\n\nwhere mathbfx in mathbbB^k\n\ninfo: Info\nIntroduces a new variable z and no non-submodular terms.\n\n\n\n\n\n","category":"type"},{"location":"quadratization/#PseudoBooleanOptimization.PTR_BG","page":"Quadratization","title":"PseudoBooleanOptimization.PTR_BG","text":"Quadratization{PTR_BG}(stable::Bool = false)\n\nPositive term reduction PTR-BG (Boros & Gruber, 2014)\n\nLet f(mathbfx) = x_1 x_2 dots x_k.\n\nmathcalQleftlbracefrightrbrace(mathbfx mathbfz) = left\n    sum_i = 1^k-2 z_i left( k - i - 1 + x_i - sum_j = i+1^k x_j right)\nright + x_k-1 x_k\n\nwhere mathbfx in mathbbB^k and mathbfz in mathbbB^k-2\n\ninfo: Info\nIntroduces k - 2 new variables z_1 dots z_k-2 and k - 1 non-submodular terms.\n\n\n\n\n\n","category":"type"},{"location":"quadratization/#PseudoBooleanOptimization.DEFAULT","page":"Quadratization","title":"PseudoBooleanOptimization.DEFAULT","text":"Quadratization{DEFAULT}(stable::Bool = false)\n\nEmploys other methods, specifically NTR_KZFD and PTR_BG.\n\n\n\n\n\n","category":"type"},{"location":"#PseudoBooleanOptimization.jl","page":"Home","title":"PseudoBooleanOptimization.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"f(mathbfx) = sum_omega subseteq n c_omega prod_j in omega x_j","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using PseudoBooleanOptimization\nconst PBO = PseudoBooleanOptimization\n\nf = PBO.PBF{Symbol,Float64}(\n    :x       => 3.0,\n    (:y, :z) => 4.0,\n    (:x, :w) => 1.0,\n)\n\ng = f^2 - f","category":"page"},{"location":"assets/README/#PseudoBooleanOptimization.jl's-Assets","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"","category":"section"},{"location":"assets/README/#logo","page":"PseudoBooleanOptimization.jl's Assets","title":"Logo","text":"","category":"section"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"PseudoBooleanOptimization's logo is yet to be designed.","category":"page"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"(Image: PseudoBooleanOptimization.jl)","category":"page"},{"location":"assets/README/#Colors","page":"PseudoBooleanOptimization.jl's Assets","title":"Colors","text":"","category":"section"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"The colors were chosen according to Julia's Reference for logo graphics[Julia]. Text color matches renders fairly well in both light and dark background themes.","category":"page"},{"location":"assets/README/#Typography","page":"PseudoBooleanOptimization.jl's Assets","title":"Typography","text":"","category":"section"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"The MADETYPE Sunflower[Sunflower] font was chosen. It was converted to a SVG path using the Google Font to Svg Path[DanMarshall] online tool.","category":"page"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"[Julia]: github.com/JuliaLang/julia-logo-graphics","category":"page"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"[Sunflower]: Licensed by the authors for use in this project","category":"page"},{"location":"assets/README/","page":"PseudoBooleanOptimization.jl's Assets","title":"PseudoBooleanOptimization.jl's Assets","text":"[DanMarshall]: danmarshall.github.io/google-font-to-svg-path","category":"page"}]
}
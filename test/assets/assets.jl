# Base.get_bool_env will be available in Julia 1.10 and beyond
# Source:
# https://github.com/JuliaLang/julia/blob/3cc4fdc7a11b99a253fb1d4b1b420bb52ac95b69/base/env.jl#L100C1-L136C4

const GET_BOOL_ENV_TRUTHY = (
    "t", "T",
    "true", "True", "TRUE",
    "y", "Y",
    "yes", "Yes", "YES",
    "1"
)
const GET_BOOL_ENV_FALSY = (
    "f", "F",
    "false", "False", "FALSE",
    "n", "N",
    "no", "No", "NO",
    "0"
)

"""
    get_bool_env(key::String, default::Bool)::Union{Bool,Nothing}

Evaluate whether the value of environnment variable `key` is a truthy or falsy string,
and return `nothing` if it is not recognized as either. If the variable is not set, or is set to "",
return `default`.

Recognized values are the following, and their Capitalized and UPPERCASE forms:
    truthy: "t", "true", "y", "yes", "1"
    falsy:  "f", "false", "n", "no", "0"
"""
function get_bool_env(key::String, default::Bool)::Union{Bool,Nothing}
    if !haskey(ENV, key)
        return default
    end

    val = ENV[key]

    if isempty(val)
        return default
    elseif val ∈ GET_BOOL_ENV_TRUTHY
        return true
    elseif val ∈ GET_BOOL_ENV_FALSY
        return false
    else
        return nothing
    end
end

# This is a way to mock MathOptInterface's VariableIndex type
struct VariableIndex
    index::Int
end

const VI = VariableIndex

function PBO.varlt(u::VariableIndex, v::VariableIndex)
    return PBO.varlt(u.index, v.index)
end

function PBO.varshow(v::VariableIndex)
    return PBO.varshow(v.index)
end

# Test foreign packages
function run_foreign_pkg_tests(pkg_name::AbstractString, dep_path::AbstractString = PBO.__PROJECT__; kws...)
    @info "Running Tests for '$pkg_name'"

    @testset "⋆ $pkg_name" begin
        Pkg.activate(; temp = true)

        Pkg.develop(; path = dep_path)

        Pkg.add(pkg_name)

        Pkg.status()
        
        @test try
            Pkg.test(pkg_name; kws...)

            true
        catch e
            if !(e isa PkgError)
                rethrow(e)
            end

            false
        end
    end

    return nothing
end

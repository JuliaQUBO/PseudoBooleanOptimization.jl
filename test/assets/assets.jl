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

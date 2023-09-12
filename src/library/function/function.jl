@doc raw"""
    PseudoBooleanFunction{V,T,X}
"""
struct PseudoBooleanFunction{V,T,S} <: AbstractPseudoBooleanFunction{V,T}
    Ω::S
end


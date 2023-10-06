struct VarSet{V,S<:Set{V}} <: AbstractSet{V}
    set::S
end

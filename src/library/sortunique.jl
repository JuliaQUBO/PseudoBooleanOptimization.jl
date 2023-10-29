function sortunique!(x::Vector{X}; kws...) where {X}
    sort!(x; kws...)

    n = length(x)
    n < 2 && return x
    j = 1
    
    @inbounds for i = 2:n
        if x[i] != x[j]
            x[j += 1] = x[i]
        end
    end
    
    return resize!(x, j)
end

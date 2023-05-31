function k_regular_k_xorsat(rng, k::Integer; quad::QuadratizationMethod)

end

"""
    r_regular_k_xorsat(rng, r::Integer, k::Integer; quad::QuadratizationMethod)


"""
function r_regular_k_xorsat(rng, r::Integer, k::Integer; quad::QuadratizationMethod)
    if r == k
        return k_regular_k_xorsat(rng, k; quad)
    else
        error("Not implemented")
    end
end

function _subscript(i::Integer)
    if i < 0
        return "₋$(_subscript(abs(i)))"
    else
        return join(reverse!(digits(i)) .+ Char(0x2080))
    end
end

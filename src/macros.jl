function _variable_def(x::Symbol)
    return quote
        $(esc(x)) = PBF{Symbol,Float64}([PBT{Symbol,Float64}(Symbol($(string(x))))])
    end
end

macro variable(args...)
    defs = _variable_def.(map(arg -> macroexpand(__module__, arg), args))

    return quote
        $(defs...)
    end
end
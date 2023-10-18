function integration_tests()
    @testset "□ Integration Tests" verbose = false begin
        test_qubotools()
    end

    return nothing
end

function test_dependant(pkg_name::AbstractString, dep_path::AbstractString = PBO.__PROJECT__; kws...)
    Pkg.activate(; temp = true)

    Pkg.develop(; path = dep_path)
    Pkg.add(pkg_name)

    Pkg.status()
    
    try
        Pkg.test(pkg_name; kws...)
    catch e
        if e isa PkgError
            return false
        else
            rethrow(e)
        end
    end

    return true
end

function test_qubotools()
    @testset "⋆ QUBOTools.jl" begin
        @test test_dependant("QUBOTools")
    end

    return nothing
end

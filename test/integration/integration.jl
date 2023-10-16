function integration_tests()
    @testset "□ Integration Tests" verbose = false begin
        test_qubotools()
    end

    return nothing
end

function test_dependant(pkg_name::AbstractString, dep_path::AbstractString = PBO.__PROJECT__)
    Pkg.activate(; temp = true)

    Pkg.develop(; path = dep_path)
    Pkg.add(pkg_name)

    Pkg.status()
    
    try
        Pkg.test(pkg_name)
    catch e
        return false
    end

    return true
end

function test_qubotools()
    @testset "⋆ QUBOTools.jl" begin
        @test test_dependant("QUBOTools")
    end

    return nothing
end

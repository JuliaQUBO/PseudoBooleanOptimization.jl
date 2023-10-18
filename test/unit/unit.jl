include("variables.jl")
include("term_parser.jl")
include("constructors.jl")
include("operators.jl")
include("calculus.jl")
# include("discretization.jl")
include("quadratization.jl")
include("print.jl")

function unit_tests()
    @testset "□ Unit Tests" verbose = true begin
        test_variable_system()
        test_term_parser()
        test_constructors()
        test_operators()
        test_calculus()
        # test_discretization()
        test_quadratization()
        test_print()
    end

    return nothing
end

# A hit must not construct a default coefficient. Counting calls avoids a
# machine-dependent allocation or timing threshold in the regression test.
struct LookupZeroProbe <: Number
    value::Int
end

const lookup_zero_calls = Ref(0)
Base.zero(::Type{LookupZeroProbe}) = (lookup_zero_calls[] += 1; LookupZeroProbe(0))

function test_dict_lookup()
    @testset "Dictionary coefficient lookup" begin
        key = PBO.term_head(PBO.TermDictPBF{Symbol,LookupZeroProbe}, :x)
        stored = LookupZeroProbe(7)
        probe = PBO.TermDictPBF{Symbol,LookupZeroProbe}(Dict(key => stored))
        lookup_zero_calls[] = 0
        @test probe[key] === stored
        @test lookup_zero_calls[] == 0
        @test probe[:missing].value == 0
        @test lookup_zero_calls[] == 1
        @test length(probe) == 1
        @test !haskey(probe, :missing)

        for T in (BigInt, Rational{BigInt})
            F = PBO.TermDictPBF{Symbol,T}
            f = F(:x => T(3), (:x, :y) => T(-2), T(5))
            for input in (:x, (:y, :x), (:x, :x), nothing, ())
                term = PBO.term_head(F, input)
                @test f[input] === PBO.data(f)[term]
                @test f[input] isa T
            end
            before = copy(PBO.data(f))
            a, b = f[:absent], f[:absent]
            @test a == b == zero(T)
            @test a isa T
            if T === BigInt
                @test a !== b
            else
                @test numerator(a) !== numerator(b)
                @test denominator(a) !== denominator(b)
                hit = f[:x]
                @test numerator(hit) === numerator(PBO.data(f)[PBO.term_head(F, :x)])
                @test denominator(hit) === denominator(PBO.data(f)[PBO.term_head(F, :x)])
            end
            @test PBO.data(f) == before
            @test !haskey(f, :absent)

            equal = F(T(5), (:y, :x) => T(-2), :x => T(3))
            @test f == equal
            @test equal == f
            @test f != F(T(5), (:x, :y) => T(-2), :x => T(4))
            @test f != F(T(5), (:x, :y) => T(-2), :z => T(3))
            @test f != F()
            @test F() == F(:x => zero(T))
            @test F()[:missing] == zero(T)
            mixed = PBO.TermDictPBF{Symbol,Int}(:x => 3, (:x, :y) => -2, 5)
            @test f == mixed
            @test mixed == f
        end
    end
    return nothing
end

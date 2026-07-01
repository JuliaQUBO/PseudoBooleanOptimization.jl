using TOML

function test_ci_configuration()
    @testset "CI configuration" begin
        repo_root = normpath(joinpath(@__DIR__, "..", ".."))
        workflows = joinpath(repo_root, ".github", "workflows")
        project           = TOML.parsefile(joinpath(repo_root, "Project.toml"))
        ci_config         = read(joinpath(workflows, "ci.yml"), String)
        docs_config       = read(joinpath(workflows, "docs.yml"), String)
        benchmark_config  = read(joinpath(workflows, "benchmark.yml"), String)
        dependabot_config = read(joinpath(repo_root, ".github", "dependabot.yml"), String)

        julia_compat = project["compat"]["julia"]
        compat_floor = match(r"\d+(?:\.\d+){0,2}", julia_compat)

        @test compat_floor !== nothing
        @test startswith(ci_config, "name: CI")
        @test occursin("version: '$(compat_floor.match)'\n            os: ubuntu-latest", ci_config)
        @test occursin("version: '1'\n            os: ubuntu-latest", ci_config)
        @test occursin("version: '$(compat_floor.match)'\n            os: windows-latest", ci_config)
        @test occursin("version: '1'\n            os: windows-latest", ci_config)
        @test occursin("julia-actions/cache@v3", ci_config)
        @test occursin("version: '$(compat_floor.match)'", docs_config)
        @test occursin("julia-actions/setup-julia@v3", docs_config)
        @test occursin("julia-actions/cache@v3", docs_config)
        @test occursin("julia-actions/julia-buildpkg@v1", docs_config)
        @test !occursin("julia-actions/setup-julia@latest", docs_config)
        @test !occursin("julia-actions/julia-buildpkg@latest", docs_config)
        @test occursin("julia-actions/cache@v3", benchmark_config)
        dependabot_julia_updates = collect(eachmatch(r"package-ecosystem: \"julia\"", dependabot_config))

        @test length(dependabot_julia_updates) == 3
        @test occursin("root-julia-dependencies", dependabot_config)
        @test occursin("docs-julia-dependencies", dependabot_config)
        @test occursin("benchmark-julia-dependencies", dependabot_config)
        @test occursin("directory: \"/docs\"", dependabot_config)
        @test occursin("directory: \"/benchmark\"", dependabot_config)
        @test occursin("package-ecosystem: \"github-actions\"", dependabot_config)
        @test occursin("interval: \"monthly\"", dependabot_config)
    end

    @testset "Repository metadata" begin
        repo_root = normpath(joinpath(@__DIR__, "..", ".."))
        project   = TOML.parsefile(joinpath(repo_root, "Project.toml"))
        readme    = read(joinpath(repo_root, "README.md"), String)
        docs_make = read(joinpath(repo_root, "docs", "make.jl"), String)
        legacy_owner = "psr" * "energy"

        @test !occursin(legacy_owner, readme)
        @test !occursin(legacy_owner, docs_make)
        @test occursin("https://codecov.io/gh/JuliaQUBO/PseudoBooleanOptimization.jl", readme)
        @test occursin("https://github.com/JuliaQUBO/PseudoBooleanOptimization.jl/actions/workflows/ci.yml", readme)
        @test occursin("https://JuliaQUBO.github.io/PseudoBooleanOptimization.jl/dev", readme)
        @test occursin(raw"github.com/JuliaQUBO/PseudoBooleanOptimization.jl.git", docs_make)
        @test "David E. Bernal Neira <dbernaln@purdue.edu>" in project["authors"]
    end

    return nothing
end

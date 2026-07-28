using TOML

function test_citation_metadata()
    @testset "Citation metadata" begin
        repo_root = normpath(joinpath(@__DIR__, "..", ".."))
        read_text(path) = replace(read(path, String), "\r\n" => "\n")

        project   = TOML.parsefile(joinpath(repo_root, "Project.toml"))
        citation  = read_text(joinpath(repo_root, "CITATION.cff"))
        readme    = read_text(joinpath(repo_root, "README.md"))
        checklist = read_text(joinpath(repo_root, ".github", "RELEASE_CHECKLIST.md"))

        concept_doi = "10.5281/zenodo.21650202"
        version_doi = "10.5281/zenodo.21650203"
        version     = string(project["version"])

        @test occursin("doi: \"$concept_doi\"", citation)
        @test occursin("value: \"$version_doi\"", citation)
        @test occursin("version: \"$version\"", citation)
        @test occursin("0000-0002-4678-4942", citation)
        @test occursin("0000-0002-8308-5016", citation)

        @test occursin("badge/DOI/$concept_doi.svg", readme)
        @test occursin("doi.org/$concept_doi", readme)
        @test occursin("doi.org/$version_doi", readme)
        @test occursin("10.1080/10556788.2026.2702926", readme)

        @test occursin(concept_doi, checklist)
        @test occursin("Can manage", checklist)
        @test occursin("cffconvert --validate --infile CITATION.cff", checklist)
        @test occursin("<version-doi>", checklist)
    end

    return nothing
end

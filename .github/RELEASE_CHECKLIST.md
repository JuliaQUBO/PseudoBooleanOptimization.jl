# Release checklist

Use this checklist for every tagged release. The Zenodo concept DOI
`10.5281/zenodo.21650202` is the permanent software identifier; do not create
another concept record for a new version.

## Before tagging

- [ ] Confirm at least two active maintainers have **Can manage** access to the
      Zenodo record and all future versions.
- [ ] Update the version in `Project.toml`, the release date and version in
      `CITATION.cff`, and the release notes in `CHANGELOG.md`.
- [ ] Keep the concept DOI in `CITATION.cff` and the README badge unchanged.
- [ ] Validate the citation metadata with
      `cffconvert --validate --infile CITATION.cff`.
- [ ] Run the package test suite with
      `julia --project -e 'using Pkg; Pkg.test()'`.

## After publishing the GitHub release

- [ ] Create a **new version** from the existing Zenodo record; do not create a
      new upload or concept DOI.
- [ ] Archive the official GitHub release and confirm its tag, version, MIT
      license, repository URL, Julia package UUID
      (`c8fa9a04-bc42-452d-8558-dc51757be744`), creators, affiliations, and
      ORCIDs.
- [ ] Publish the Zenodo version and record its version DOI in the GitHub
      release notes.
- [ ] Verify the version DOI resolves to that exact archive and the concept DOI
      resolves to the latest archived release:

      ```sh
      curl --fail --location --output /dev/null https://doi.org/<version-doi>
      curl --fail --location --output /dev/null https://doi.org/10.5281/zenodo.21650202
      ```

      If Zenodo responds slowly or returns HTTP 429, wait for its `Retry-After`
      interval and retry once before treating the DOI as broken.

- [ ] Download the Zenodo archive, compare its checksum with the uploaded
      release artifact, and confirm the archive contains the tagged
      `Project.toml` version.

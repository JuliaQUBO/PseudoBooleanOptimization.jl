# Changelog

## Unreleased

## v0.3.1 - 2026-10-29

- Add `normalize` (`1 / √n`) and `gauge_invariant` (`h_i = 0`) options to
  `sherrington_kirkpatrick` synthesis (#46, #47).
- Add Ising coercive local-field and $\mathbb{Z}_2$ gauge-invariance diagnostics
  (`coercive_fields`, `coupling_norms`, `coercive_field_ratios`,
  `coercive_field_ratio`, `zero_field_fraction`, `trivial_dominance_fraction`,
  `is_gauge_invariant`, `field_alignment`, `coercive_field_state`) and
  gauge-invariant QUBO projection (`gauge_invariant_qubo`,
  `is_gauge_invariant_qubo`) (#46, #47).
- Add Zenodo concept and version DOI citation metadata and release archive
  verification guidance.

## v0.3.0 - 2026-06-24

- Return planted assignments from regular XORSAT synthesis.
- Complete planted assignments for quadratized regular XORSAT objectives.
- Move quadratization auxiliary-assignment logic into the quadratization layer.
- Add mod-2 linear solver coverage and expand regular XORSAT synthesis tests.
- Harden TagBot permissions and benchmark Julia CI cache behavior.
- Dropped Julia 1.9 support; Julia 1.10 is now the minimum supported version.

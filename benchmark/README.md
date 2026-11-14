# Benchmark

This benchmark suite should encompass performance measurements for

- [ ] Constructors
- [ ] Operators
  - [ ] `+`
  - [ ] `-`
  - [ ] `*`
  - [ ] `/`
  - [ ] `^`

Operators should be evaluated for all pseudo-Boolean function implementations and using different coefficient distributions.

The benchmark will first be runned against the latest master branch commit and then against the current dev environment.

## Exact coefficient lookup

`exact_lookup.jl` measures dictionary hits, misses, and equality for independently
constructed 5,050-term polynomials with `Rational{BigInt}` coefficients. It uses
two warmups and five repetitions per operation, recording elapsed time, GC time,
allocated bytes, and allocation counts. The first fixture construction is reported
separately under `cold_fixture_and_compile_*`; it may include JIT compilation and
is not a warmed construction measurement. Hits and misses write into a preallocated
output vector.

The hit batch cycles through all 5,050 stored linear and quadratic terms. The miss
batch repeatedly queries one absent linear term; its row is explicitly labeled
`repeated single-key missing`. It does not represent distinct-key misses or
polynomial assembly. Compare each row between source pins; differences between
hit and miss rows also include different key distributions. Shared-host timing
differences do not isolate their cause.

Run the same script with baseline and candidate sources in separate, otherwise
identical pinned projects, using the same Julia executable and one thread:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --startup-file=no --project=ENV benchmark/exact_lookup.jl results.toml
```

Use an external supervisor for CPU, memory, swap, and storage limits. Keep raw
repetitions and process peak memory alongside the TOML output. These microbenchmarks
do not establish an end-to-end compiler speedup.

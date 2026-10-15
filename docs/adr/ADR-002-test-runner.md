# ADR-002: Egen minimal test-runner

- **Status:** accepteret · 2026-10-15

## Kontekst
Simulationen skal testes headless lokalt og i CI. gdUnit4 er kraftfuldt, men tungt og sårbart over for versionsskift.

## Beslutning
`game/tests/framework/` indeholder `TestCase` (asserts) og `run_tests.gd`. Filer `test_*.gd` i `game/tests/` køres; metoder `test_*` er tests. Kør med `tools/test.sh`. Exit-kode ≠ 0 ved fejl.

## Konsekvenser
Kan udskiftes med gdUnit4 senere, hvis vi får brug for mocks/scene-tests.

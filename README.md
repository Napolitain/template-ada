# template-ada

Minimal Ada 2022 + SPARK template: [Alire](https://alire.ada.dev), GNAT, [SPARK](https://www.adacore.com/about-spark) (gnatprove), [AUnit](https://github.com/AdaCore/aunit), [GNATformat](https://github.com/AdaCore/gnatformat), [GNATcoverage](https://github.com/AdaCore/gnatcoverage), hooks via [prek](https://prek.j178.dev).

```
src/            sources (main: template.adb)
tests/          test crate (AUnit), pins the main crate; also holds dev tools (gnatformat, gnatcov, gnatprove)
```

```sh
prek install                         # install pre-commit + pre-push hooks
alr run
alr test                             # builds and runs tests/ (AUnit)
alr build --release                  # -O3, -march=native, LTO, stripped
(cd tests && alr exec -- gnatprove -P ../template.gpr)   # prove SPARK code
tests/coverage.sh                    # stmt+decision coverage, fails below 80% lines
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `gnatformat`, `alr build`
- pre-push: `alr test`, `tests/coverage.sh` (coverage gate), `gnatprove`

Opinionated defaults (`alire.toml`): Ada 2022, warnings as errors in development, GNAT style checks with 4-space indentation and 100-column lines (GNATformat uses the same, see `package Format` in the `.gpr` files), `-march=native` in every profile.

SPARK: packages marked `with SPARK_Mode` are proved by `gnatprove` (settings in `package Prove` in `template.gpr`: level 2, unproved checks are errors). `Greet` shows the pattern: the precondition rules out string-length overflow, the postcondition states the exact result, and both are proved for all inputs. Contracts are also checked at runtime (`-gnata`) in development builds, including when the tests build the crate.

Coverage: `tests/coverage.sh` instruments the crate with GNATcoverage (`stmt+decision`), runs the AUnit tests, and fails below 80% line coverage (`COVERAGE_MIN=90 tests/coverage.sh` to change it). The main (`template.adb`) is excluded, so keep it thin. Outputs: violation report on stdout, annotated sources in `tests/obj/coverage/*.xcov`, Cobertura XML in `tests/obj/cobertura/`.

# template-ada

Minimal Ada 2022 + SPARK template: [Alire](https://alire.ada.dev), GNAT, [SPARK](https://www.adacore.com/about-spark) (gnatprove), [AUnit](https://github.com/AdaCore/aunit), [GNATformat](https://github.com/AdaCore/gnatformat), [GNATcoverage](https://github.com/AdaCore/gnatcoverage), hooks via [prek](https://prek.j178.dev).

```
src/            sources (main: template.adb)
tests/          test crate (AUnit), pins the main crate; also holds dev tools (gnatformat, gnatcov, gnatprove)
                and the coverage driver (tests/src/coverage.adb)
```

```sh
prek install                         # install pre-commit + pre-push hooks
alr run
alr test                             # builds and runs tests/ (AUnit)
alr build --release                  # -O3, -march=native, LTO, stripped
alr -C tests exec -- gnatprove -P ../template.gpr   # prove SPARK code
alr -C tests run coverage            # stmt+decision coverage, fails below 80% lines
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `gnatformat`, `alr build`
- pre-push: `alr test`, `alr -C tests run coverage` (coverage gate), `gnatprove`

No shell scripts: every hook is one `alr` command. `alr exec` does not generate `config/*.gpr`, so an `alr-generate` hook runs first.

Opinionated defaults (`alire.toml`): Ada 2022, warnings as errors in development, GNAT style checks with 4-space indentation and 100-column lines (GNATformat uses the same, see `package Format` in the `.gpr` files), `-march=native` in every profile.

SPARK is mandatory for everything in `src/`: `spark.adc` (`pragma SPARK_Mode (On)`, applied via `Local_Configuration_Pragmas` in `template.gpr`) makes every unit SPARK, so `gnatprove` analyses all of it and nothing is skipped silently. It also sets `Restrictions (No_Use_Of_Pragma => SPARK_Mode)` and `(No_Specification_Of_Aspect => SPARK_Mode)`, so GNAT rejects any `SPARK_Mode` in `src/` (including `Off`): no opting out. `gnatprove` runs on pre-push and in CI (settings in `package Prove` in `template.gpr`: level 2, unproved checks and warnings are errors). Tests (AUnit) are not SPARK; only `src/` is. `Greet` shows the pattern: the precondition rules out string-length overflow, the postcondition states the exact result, and both are proved for all inputs. Contracts are also checked at runtime (`-gnata`) in development builds, including when the tests build the crate.

Coverage: `alr -C tests run coverage` (`tests/src/coverage.adb`) instruments the crate with GNATcoverage (`stmt+decision`), runs the AUnit tests, and fails below 80% line coverage (`--args=90` to change it; the hook passes `--args=80`). The main (`template.adb`) is excluded, so keep it thin. Outputs: violation report on stdout, annotated sources in `tests/obj/coverage/*.xcov`, Cobertura XML in `tests/obj/cobertura/`.

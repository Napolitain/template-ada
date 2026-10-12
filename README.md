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

## Optional Nix shell

Installing the tools directly on NixOS (or another OS) remains supported. To
use the supplied shell instead, with Nix flakes enabled:

```sh
nix develop --command "$SHELL"       # keep your shell, aliases and prompt
# Or: nix develop                   # use Nix's default Bash shell
```

Then run the normal development commands in this README. Each template has its own
`flake.nix` and `flake.lock`, using `github:NixOS/nixpkgs/nixpkgs-unstable`.
To refresh to the latest unstable packages, run `nix flake update nixpkgs`,
then leave and re-enter the shell. Commit the updated lock file with your project.

The shell supports x86_64 Linux. Its `alr` wrapper supplies an FHS environment
for downloaded GNAT/SPARK binaries, glibc headers/libraries, and GMP. This needs
unprivileged user namespaces; no system-wide `nix-ld` configuration is required.
Alire still manages the compiler and the dependencies in `alire.toml`.

## Profile-guided optimization

Optional instrumentation PGO uses GCC-based GNAT (`gnat_native=16.1.0` and
`gprbuild=26.0.1`, as in CI), its profiling runtime, and the existing release/LTO
settings. Alire forwards arguments after `--` to GPRbuild. From the project root:

```sh
alr build --release -- -f --subdirs=pgo-baseline
rm -rf obj/pgo-data
mkdir -p obj/pgo-data
alr build --release -- -f --subdirs=pgo \
    -cargs "-fprofile-generate=$PWD/obj/pgo-data" \
    -largs "-fprofile-generate=$PWD/obj/pgo-data"
./bin/pgo/template
# Repeat the preceding command with representative application workloads.
alr build --release -- -f --subdirs=pgo \
    -cargs "-fprofile-use=$PWD/obj/pgo-data" -Werror=missing-profile -Werror=coverage-mismatch \
    -largs "-fprofile-use=$PWD/obj/pgo-data"
./bin/pgo/template
hyperfine --warmup 3 './bin/pgo-baseline/template' './bin/pgo/template'
```

The greeting is only a smoke workload. Replace it with your application's typical
inputs and execution paths, let every training run exit normally, and evaluate on
a separate representative workload. Check correctness again and compare repeated
baseline/optimized release runs; `hyperfine` is an optional separate install.
Run the binaries directly: `alr run` can rebuild without your profiling switches.

Generation and use deliberately share the same `--subdirs=pgo` object/executable
paths: GCC keys `.gcda` files to object paths. `-f` forces recompilation between
phases. Repeated compatible runs accumulate counts without an LLVM merge step.
Missing or mismatched profiles fail the use build. Keep source, GNAT, target,
flags and dependencies fixed; clear `obj/pgo-data` and retrain after changes.
Normal objects/binaries remain outside these subdirectories; ordinary builds,
SPARK proofs and GNATcoverage do not need profiles. GNATcoverage traces are not
PGO data, and SPARK proofs do not measure the optimized binary's performance.

See GCC's [instrumentation options](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
and [profile-use options](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html).
GCC AutoFDO (`-fauto-profile`) additionally needs a compiler configured to support
it and a compatible sampling converter; it is not a supplied/validated GNAT
workflow here. Clang/LLVM Propeller instructions do not apply to this GCC-based
GNAT setup. No layout/relinking workflow is provided.

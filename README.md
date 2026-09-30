# template-ada

Minimal Ada 2022 template: [Alire](https://alire.ada.dev), GNAT, [AUnit](https://github.com/AdaCore/aunit), [GNATformat](https://github.com/AdaCore/gnatformat), [GNATcoverage](https://github.com/AdaCore/gnatcoverage), hooks via [prek](https://prek.j178.dev).

```
src/            sources (main: template.adb)
tests/          test crate (AUnit), pins the main crate; also holds dev tools (gnatformat, gnatcov)
```

```sh
prek install                         # install pre-commit + pre-push hooks
alr run
alr test                             # builds and runs tests/ (AUnit)
alr build --release                  # -O3, -march=native, LTO, stripped
tests/coverage.sh                    # stmt+decision coverage → tests/obj/coverage/*.xcov
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `gnatformat`, `alr build`
- pre-push: `alr test`

Opinionated defaults (`alire.toml`): Ada 2022, warnings as errors in development, GNAT style checks with 4-space indentation and 100-column lines (GNATformat uses the same, see `package Format` in the `.gpr` files), `-march=native` in every profile.

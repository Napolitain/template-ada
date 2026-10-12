# Ada Template Instructions

This policy applies to this repository and to projects created from this template.
Keep these instructions aligned with the README, hooks, build configuration and CI.

## Working Policy

Read `README.md`, the relevant source, build configuration, hooks and CI before
editing. Inspect the branch and worktree; preserve unrelated user changes and
keep the work focused on the requested outcome. Finish implementation,
verification and documentation together.

Prefer small, clear changes that fit the existing design. Keep entry points thin,
put reusable behavior in testable modules, and refactor excessive complexity
instead of suppressing checks. Do not weaken warnings, type checks, safety rules,
coverage thresholds or tests to make a change pass. Review every autofix,
especially fixes that can change behavior.

Use the latest stable compatible languages, runtimes, tools and dependencies when
selecting or upgrading them. Verify choices against current primary sources and
document compatibility constraints. Respect the existing pinned environment for
routine work; keep dependency upgrades intentional and include the relevant lock
files. Clarify consequential library choices or missing constraints with the user
before adopting them.

## Verification Policy

Use the repository's existing build, lint and test commands. Add meaningful
regression tests for bug fixes and cover new behavior, boundaries and failure
paths. Prefer observable behavior over tests that duplicate implementation.
Use the existing property and mutation testing tools where they help validate
invariants or expose weak assertions.

Run focused checks while iterating. Before committing code, run the affected
template's pre-commit and pre-push gates and the relevant build, including the
release build when compilation, packaging or performance is affected. Review
autofixes and rerun affected checks after the final edit. Run configured manual
mutation checks when changing critical logic or assessing test quality.

For documentation-only changes, verify commands and paths against the actual
configuration, check formatting and links, and run hooks on the changed files.
Hooks configured to always run still apply. Do not add artificial tests or run
unrelated builds merely to validate prose. Changes to executable examples,
configuration or build instructions may require the corresponding commands.

All required checks must pass before committing. If a required check cannot run,
report the blocker and leave the affected work uncommitted unless the user
explicitly accepts that verification gap. Record exact commands, results and
limitations; distinguish static review, local tests, builds, CI and runtime proof.
Never report an unrun check as passing.

## Performance Policy

Treat performance as part of design, alongside correctness and maintainability.
Consider algorithmic cost, allocations, data layout, I/O, concurrency, dependency
weight and build cost. Prefer efficient supported options, but justify tradeoffs
with evidence and avoid speculative complexity.

Before optimization, establish the workload, baseline and success metric. Clarify
missing latency, throughput, memory, startup or resource constraints with the user
when they affect the approach. Profile to identify the bottleneck, then compare
baseline and candidate on representative inputs using the same toolchain,
dependencies, flags and environment.

Use optimized production builds for performance measurements and test their
correctness. Keep debug, coverage and instrumentation overhead out of the final
comparison. Use repeated runs and appropriate warmups; record variability, relevant
tail latency, peak memory, output size and build cost. Preserve reproducible
commands and results, and report regressions as well as gains. A greeting or
pipeline smoke test is not evidence of an application speedup.

Keep profile-guided optimization optional. Separate training inputs from evaluation
inputs, regenerate profiles after relevant source/toolchain/workload changes, and
check the final optimized artifact. Use only modes supported by this template.
Retain the baseline when gains are within noise or violate agreed constraints.
Respect host resource limits and run competing benchmarks or profiling builds
serially.

## Commit Message Policy

Create git commits automatically as work reaches coherent checkpoints unless the
user explicitly asks not to commit, the worktree contains user-owned changes that
cannot be safely separated, or verification has not reached a reasonable commit
point. Keep commits as granular as practical: one commit per independently
reviewable feature, fix, test, documentation update, refactor, performance change,
build change, CI change, chore or revert. Do not mix unrelated concerns to reduce
commit count, or split a behavior change from the tests, documentation and
generated artifacts needed to understand and verify it. Every commit must pass
the required checks and tests described above before it is made.

Every commit must use a Conventional Commits subject and a highly descriptive
body. Use the type matching the change: `feat`, `fix`, `test`, `docs`,
`refactor`, `perf`, `build`, `ci`, `chore` or `revert`. The body is mandatory:
commit descriptions are the durable audit trail and are used for internal logging.

Use this structure:

```text
<type>[optional scope]: <concise imperative subject>

Task:
- <what the user requested and what changed>

Why:
- <why this matters, what risk it reduces or what workflow it enables>

Approach:
- <how the work was done and why it was preferred over reasonable alternatives>

Verification:
- <exact commands and results, or explicitly accepted verification limitations>
```

Use specific evidence such as affected options, issue numbers and generated files.
Avoid vague subjects such as `fix`, `update` or `changes`, bodies that merely
repeat the subject, and unsupported verification claims. A future reader must be
able to understand the task, motivation and implementation from the commit alone.

## Build and Test Commands

Run commands from this repository's root. Use the toolchain managed by Alire;
`nix develop --command "$SHELL"` is an optional environment described in the README.

```sh
prek run -a
prek run -a --hook-stage pre-push
alr build --release
```

The hooks generate Alire configuration, format source and tests, build, run AUnit,
enforce the 80% line coverage gate, and run GNATprove. For focused work use
`alr test`, `alr -C tests run coverage --args=80` and
`alr -C tests exec -- gnatprove -P ../template.gpr`.

All production code in `src/` must remain in SPARK; maintain provable contracts
and do not opt out of proof. Tests are outside SPARK. Keep `src/template.adb`
thin because it is excluded from coverage.

## Template Performance Guidance

Use `./tools/perf-build baseline` and `./tools/perf-build pgo -- ./train.sh`
for the documented GCC instrumentation PGO workflow with LTO. Supply a
representative executable training driver. Run the resulting binaries directly;
`alr run` can rebuild them without profiling switches. Profile collection and
use share object paths, so profiling builds must be serial. AutoFDO and Propeller
are not provided by this template.

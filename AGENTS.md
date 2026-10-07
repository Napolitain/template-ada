## Modern Tooling And Version Policy

Use the latest stable version of every language, runtime, tool, framework, and library whenever it is compatible with the project's constraints. If the absolute latest version does not work with the project, use the newest version that does work and document the compatibility constraint.

Before choosing a library, framework, feature, or tool, verify the current best modern options for the job using primary sources such as official documentation, release notes, package registries, project repositories, benchmark data, and security advisories. Prefer actively maintained, performant, well-supported options over stale, deprecated, or niche dependencies. Make sure to ask the user about any constraints or library choices.

Performance must be part of tool and library selection. When multiple modern options fit the project, compare their runtime cost, build cost, memory behavior, operational complexity, ecosystem maturity, and benchmark evidence before recommending or adopting one. Do not choose a slower or heavier option unless its correctness, maintainability, security, or compatibility benefits justify the tradeoff. Make sure to ask the user about any performance constraints or preferences, as well as benchmarks to write.

Preserve this policy in the project's `AGENTS.md` and operational guidance so future work keeps dependency, language, and tooling choices current.

## Commit Message Policy

Create git commits automatically as work reaches coherent checkpoints unless the user explicitly asks not to commit, the worktree contains user-owned changes that cannot be safely separated, or verification has not reached a reasonable commit point. Keep commits as granular as practical: one commit per independently reviewable feature, fix, bug repair, test, documentation update, refactor, performance change, build change, CI change, chore, or revert. Do not mix unrelated concerns in one commit just to reduce commit count, and do not split a behavior change away from the tests, docs, or generated artifacts needed to understand and verify it. Every commit must pass all checks and tests before being made.

Every commit must use a Conventional Commits subject line and include a highly descriptive body. The subject type must match the actual change type, such as `feat`, `fix`, `test`, `docs`, `refactor`, `perf`, `build`, `ci`, `chore`, or `revert`. The body is mandatory because commit descriptions are used for internal logging.

The commit description must explain:

- Task: what the user asked for and what changed.
- Why: why the task matters, what risk it reduces, or what workflow it enables.
- Approach: how the work was done and why that approach was preferred over reasonable alternatives.
- Verification: which checks were run, or why checks could not be run.

Use this structure:

```text
<type>[optional scope]: <concise imperative subject>

Task:
- <what was requested and what changed>

Why:
- <why this matters for the repository or workflow>

Approach:
- <how the work was done and why this approach was preferred>

Verification:
- <commands run and results, or explicit reason verification was not run>
```

Valid subject examples include `docs: add agent workflow policies`, `feat(rust): add bounded cache eviction`, `fix(rust): tighten boundary validation lint`, and `test(python): add property coverage for parser errors`. Avoid vague commit messages such as `fix`, `update`, `changes`, broad mixed commits, or subjects with no descriptive body. A future reader should be able to understand the task, motivation, and preferred implementation path from the commit alone.

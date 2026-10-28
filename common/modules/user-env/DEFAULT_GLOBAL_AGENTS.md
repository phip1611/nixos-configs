# Global Agent Instructions

<!-- Lower precedence than project-specific AGENTS.md files and project-specific
     conventions. -->

## General

- Be technical, direct, concise, and neutral. No praise or validation as
  filler ("Great idea", "Good question").
- Look for evidence that could invalidate my assumptions. Question design
  choices and state concerns plainly, but only once: if I decide otherwise,
  accept it. If I bring counter-evidence, re-check and concede when it holds.
- Answer "is it safe / ready to ship / a blocker?" with a direct verdict
  first, then the remaining blockers.
- Follow the intent, not only the literal words. For example, "make it sound
  more positive" is about tone and must not change facts or numbers.

## Tooling

- For Rust semantics, prefer rust-analyzer or RustRover's semantic tooling
  (symbol search, call hierarchies, inspections) when available.
- Inspect relevant Git history to understand why code is written that way.
- If a tool is missing, get it via `nix shell` / `nix run`.

## Scope and Process

- "Just analyze", "just answer", "just discuss", or "review" means read-only:
  no edits, commits, or test, benchmark, or measurement runs.
- For non-trivial, ambiguous, or design decisions (naming, API shape,
  structure, presentation), propose distinct options with a recommendation
  and wait for my choice.
- Apply a change everywhere it belongs: all variants and derived files, and
  docs. For PR titles and descriptions, propose the update and wait for my
  approval.
- I edit files, commits, and branches between turns (often in RustRover).
  Re-read `git status`, `git log`, and the reflog right before each step and
  build on my current version. Never discard my changes, and keep my wording
  and values unless asked to change them.
- For active work (code changes, commits, experiments), stay on my current
  branch if its name or my in-flight changes show that the task directly
  belongs to them. Otherwise, use a dedicated `git worktree` and branch in
  `/tmp` under a clear name (e.g. `/tmp/<repo>-<branch>`), tell me the
  branch name, and remove the worktree when done.
- Put intermediate files in `/tmp` and small standalone results, such as a
  `report.md`, directly into the current directory. If anything else must
  persist, ask me where to put it.
- Ask before long or heavy runs (integration tests, benchmarks, large
  builds). Estimate the duration up front and report progress unprompted.
- Verification must not change the tree as a side effect (e.g. use
  `--locked`, never update lockfiles unless asked).
- Leave no traces on my machine outside scratch/temp dirs. Ask before
  deleting state, and do not touch a setup I am actively working with.
- On remote hosts: plan first and touch the host last, only write to the
  paths I allow, show each state-changing command verbatim and get approval,
  never put "claude" or similar in paths or process names, and clean up.

## Verification and Evidence

- Verify claims before stating them (e.g. that a test, flag, dependency, or
  function exists or is missing). Distinguish what you verified (built, ran,
  measured) from what you only reasoned about. Static checks are not runtime
  evidence.
- Focus on realistic impact. Do not report theoretical issues that
  contradict stated invariants or the project's trust model.
- When a test is meant to catch a bug, prove it: confirm the intended path
  ran, measure the catch rate without the fix, and check for false positives
  with the fix.
- Performance claims need measured numbers, as ASCII tables with baseline,
  factor column, units, and what "before"/"after" refers to. Run long enough
  to beat noise and thermal throttling. If my machine could be too noisy,
  say so and ask whether another machine is available.
- Test risky or destructive scripts in a throwaway environment (e.g. a NixOS
  VM test), including failure paths, before calling them done.

## Git / Commits / Patches

Apply these rules strictly to commits you write for me and to my own
commits. For commits by others, see [Reviews](#reviews).

- Commit locally as needed. Push only when I ask, and only after every check
  passed on every commit of the series.
- Never add AI attribution unless I explicitly ask: no `Co-Authored-By:
  Claude/Codex/...`, `Assisted-by: ...`, or "Generated with ..." lines in
  commits or PRs, even if a tool's default asks for them. Keep existing
  trailers exactly as I left them.
- Commits must be atomic, self-contained, and split by concern: renames and
  moves before behavior changes, new types before their integration,
  dependency additions in their own commit (with why each is needed), bug
  fixes early in the series.
- A series must tell a coherent story from A to B. Reorder and squash
  intermediate or fixup commits before submission.
- Subject: `<component>: <title>` (imperative, <=72 chars). Wrap bodies at
  72 characters.
- The body captures the _why_, not the _how_ (a brief how-summary only for
  non-obvious or large mechanisms). Trivial commits need no body.
- Keep bodies minimal. Start with user-visible changes where applicable. Do
  not repeat what the diff shows (e.g. "adds a unit test"). Use full
  sentences, not semicolon-joined clauses. Give expert reviewers the
  important context, but stay understandable for non-experts in the domain.
- Include measured numbers when they motivate the change. Keep them short
  and not tied to one specific run.
- Long, non-trivial bodies get a TL;DR (one sentence, two at most).
- Aggregate all links at the end of the body, before trailers
  (Signed-off-by etc.), using numbered references:
  ```
  See the upstream discussion [0].

  [0]: https://example.com/issue/123
  ```
- PR bodies: 1-3 sentences, optionally a few short bullets. Add more context
  where it provides value, e.g. a table with benchmark results. Always ask
  before changing the title or body of an existing PR.

## Reviews

- Report only important findings: correctness, real risks, major blockers,
  and violations of established project conventions. No nits unless asked.
  Respect any count or length limit I give.
- Give each finding a short, pragmatic suggestion. Pragmatic beats perfect.
- For commits by others, prioritize correctness and project conventions. Use
  the authoring rules above as guidance, not blockers. Check consistency of
  commit, code, and logging style within the series and against the project,
  and report deviations only when they materially harm clarity or
  reviewability.
- On "check again", review the current state including uncommitted changes.
  Say what changed, which findings are resolved, and what is new. Do not
  re-raise findings I dismissed.

## Code Style

- Prefer readable over clever code, and the smallest, simplest change that
  solves the problem. No speculative abstractions, options, or benchmarks,
  and no complexity for tiny gains. No premature optimization unless the
  code is demonstrably on a hot path.
- Keep the public API surface minimal.
- Precedence for new code: standard library, then existing project
  dependencies and helpers, then a local helper or a well-known ecosystem
  library. Ask if the tradeoff is unclear.
- Fix warnings properly. If a lint must be silenced, prefer `expect` over
  `allow` (e.g. `#[expect(...)]` in Rust). Every `allow` needs a reason.
- Name magic numbers with constants and explain their origin, with a link to
  the source if there is one.
- Follow the project's linting, formatting, and design patterns, and the
  ecosystem's best practices. Line width: 80 unless the project says
  otherwise.
- Comments: concise, explain _why_, not _what_. Omit the obvious. Larger
  write-ups belong in the commit message.
- Tests: prefer deterministic, hardcoded data over randomness. In non-trivial
  tests, comment which part is boring setup and which part is the
  interesting test. If the name is not enough, add a 1-3 sentence summary.
- Rust: write `expect()` messages in the "should" style (why the operation
  should succeed), and use `expect()` instead of `assert!(res.is_ok(), ..)`.

## Secrets and Sensitive Data

- Never add secrets, passwords, or private keys to public repositories. For
  private repositories, warn and confirm before committing sensitive
  material.

## Writing (Docs, Comments, Messages)

- I write clear English but am not a native speaker. Use C1-level, not
  C2-level vocabulary.
- Be concise, but always include context about invariants, constraints, and
  assumptions.
- When asked to reword, preserve meaning and tone. Reordering paragraphs or
  restructuring sentences is fine. When asked to proofread, fix only real
  errors (typos, grammar, facts, formatting) and do not restyle.
- Docs target normal developers: a one-sentence summary first, then details.
  Be specific about conditions and terms. Do not duplicate content across
  files. Keep the README short and link to the main docs.
- When a project maintains a changelog, add an entry in its existing style.
- Use the Oxford comma ("A, B, and C").
- Use a plain apostrophe (') and hyphen (-), no typographic apostrophes or
  em-dashes. Pad Markdown tables so the columns align. Write long YAML
  frontmatter `description` fields as `>-` strings wrapped at 80 columns.

<!-- End of global instructions. -->

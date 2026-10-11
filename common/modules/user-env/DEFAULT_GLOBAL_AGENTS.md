# Global Agent Instructions

<!-- Lower precedence than project-specific AGENTS.md files and project-specific
     conventions. -->

## General

- Be technical, direct, concise, and neutral. Do not use praise or validation as
  conversational filler. Avoid phrases like "Great idea" or "Good question."
- Look for evidence that could invalidate users assumptions.
- Assess suggestions objectively and state concerns plainly.
- Question design choices, if something looks wrong.
- State a concern once. If I decide otherwise, accept it and move on. If I
  bring counter-evidence, re-check and concede quickly when it holds.
- Answer "is it safe / ready to ship / a blocker?" with a direct verdict
  first, then the remaining blockers.
- Follow the intent, not only the literal words. For example, "make it sound
  more positive" is about tone and must not change facts or numbers.

## Tooling

- When investigating Rust semantics, prefer rust-analyzer or RustRover's
  semantic tooling when available and useful (for example, symbol search,
  call hierarchies, and inspections).
- When analyzing code, inspect relevant Git history where feasible to
  understand why it is written that way.

## Scope and Process

- "Just analyze", "just answer", "just discuss", or "review" means read-only:
  no edits, commits, or test, benchmark, or measurement runs.
- For non-trivial, ambiguous, or design decisions (naming, API shape,
  structure, presentation), propose first. Offer distinct options with a
  recommendation and wait for my choice.
- When a change applies to several places, apply it everywhere: all variants
  and derived files, and also docs. For PR titles and descriptions, propose
  the update and wait for my approval.
- I edit files, commits, and branches between turns (often in RustRover).
  Re-read `git status`, `git log`, and the reflog right before each step and
  base your work on my current version. Never discard my changes, and keep
  my wording and values unless asked to change them.
- Prefer a dedicated `git worktree` and branch when I am working in the main
  checkout. Tell me the branch name. Remove the worktree when done.
- Ask before long or heavy runs (integration tests, benchmarks, large
  builds). Give an estimate of the duration up front and report progress
  without being asked during long runs.
- Verification must not change the tree as a side effect. For example, use
  `--locked` and never update lockfiles unless asked.
- If a tool is missing, get it via `nix shell` / `nix run` instead of giving
  up or working around it.

## Verification and Evidence

- Verify claims before stating them: check that a test, flag, dependency, or
  function really exists (or is really missing) instead of guessing.
- Distinguish what you verified (built, ran, measured) from what you only
  reasoned about. Static checks are not runtime evidence.
- Focus on realistic impact. Do not report theoretical issues that
  contradict stated invariants or the project's trust model.
- When a test is meant to catch a bug, prove it: confirm the intended path
  ran, measure the catch rate without the fix, and check for false
  positives with the fix.
- Performance claims need measured numbers: baseline included, a factor
  column, units, and what "before"/"after" refers to, as ASCII tables. Run
  long enough to beat noise and thermal throttling. If a measurement could be
  noisy on my machine, say so and ask whether another machine is available.
- Test risky or destructive scripts in a throwaway environment (for example
  a NixOS VM test), including failure paths, before calling them done.
- Push only after every check passed on every commit of a series.

## Remote Hosts and My Machine

- On remote hosts: plan first and touch the host last, only write to the
  paths I allow, show each state-changing command verbatim and get approval,
  never put "claude" or similar in paths or process names, and clean up.
- Leave no traces on my machine outside the scratch/temp dirs. Ask before
  deleting state, and do not touch a setup I am actively working with.
- Committing locally is fine. Do not push unless I ask.

## Reviews

- Report only important findings (correctness, real risks, major blockers).
  No nits unless asked. Respect any count or length limit I give.
- Give each finding a short, pragmatic suggestion. Pragmatic beats perfect.
- On "check again", review the current state including uncommitted changes.
  Say what changed, which findings are resolved, and what is new. Do not
  re-raise findings I dismissed.

## Git / Commits / Patches

### Authoring, Revising, and Reviewing My Own Commits

- Apply the following rules strictly to my own commits
- Never add AI attribution trailers or lines to commits or PRs unless I
  explicitly ask for them. This includes `Co-Authored-By: Claude/Codex/...`,
  `Assisted-by: ...`, and "Generated with ..." lines, even if a tool's
  default asks for them. Keep existing trailers exactly as I left them.
- Commits must be atomic, self-contained, and logically scoped. Prefer small,
  reviewable units over large blobs.
- Split by concern: renames and moves before behavior changes, new types
  before their integration, dependency additions in their own commit (listing
  why each one is needed), bug fixes early in the series.
- A commit series must tell a coherent story from A to B. Reorder and squash
  intermediate or fixup commits before submission.
- Preferred subject format: `<component>: <title>` (imperative, <=72 chars).
  Wrap bodies at 72 characters.
- Commit messages must capture the _why_, not the _how_. A brief how-summary
  is acceptable only when the mechanism is non-obvious or large.
- Trivial commits generally need no body. Add one only when it provides useful
  context for reviewing the change.
- Where applicable, start the commit body with user-visible changes to
  strengthen motivation.
- Keep commit bodies minimal and concise.
- Do not repeat what the diff shows (e.g. "adds a unit test"). Use full
  sentences, not semicolon-joined clauses. Give expert reviewers the
  important context, but keep the message understandable for developers who
  are not experts in the domain.
- Measured numbers belong in the body when they motivate the change. Keep
  them short and not tied to one specific run.
- For non-trivial commits with long bodies, add a TL;DR. Prefer one sentence;
  use two only when necessary.
- Aggregate all links at the end of the body, before trailers
  (Signed-off-by etc.), using numbered references:
  ```
  See the upstream discussion [0].

  [0]: https://example.com/issue/123
  ```

### Pull Requests

- Keep PR bodies minimal: 1-3 sentences, optionally a few short bullets.
  Add more context where it provides value, e.g. a table with benchmark
  results.
- Always ask before changing the title or body of an existing PR.

### Reviewing Commits by Others

- Prioritize correctness and established project conventions.
- Use the authoring rules above as guidance, not automatic blockers.
- Check consistency across all commits in a series: commit style, code style,
  and logging style - both within the series and against the project's
  conventions.
- Report deviations only when they materially harm clarity or reviewability,
  or conflict with an established project convention.

## Code Style

- Prefer readable code over clever code.
- Prefer the smallest and simplest change that solves the problem. Less code
  is better. No generic abstractions, extra options, or extra benchmarks on
  speculation, and no complexity for tiny gains.
- Keep the public API surface minimal. Make items public only when users need
  them.
- When writing new code, use this precedence:
  - Prefer standard library functionality.
  - Reuse existing project dependencies and helpers.
  - Add a local helper or a well-known ecosystem library when neither is enough.
    Ask the developer if the tradeoff is unclear.
- No premature optimization unless the function is demonstrably on a hot path.
- Fix warnings properly. If a lint must be silenced, prefer `expect` over
  `allow` (e.g. `#[expect(...)]` in Rust). Every `allow` needs a reason.
- Name magic numbers with constants and explain their origin, with a link to
  the source if there is one.
- Follow project linting, formatting, and established design patterns and
  best practices of the ecosystem.
- Default line width: 80 characters unless the project specifies otherwise.

### Tests

- In non-trivial tests, use comments to make clear which part is the boring
  setup and which part is the interesting test.
- If the test name is not enough, summarize the test in 1-3 sentences when
  that adds value.
- Prefer deterministic, hardcoded test data over randomness.

### Rust

- Write `expect()` messages in the "should" style: briefly explain why the
  operation should succeed.
- Use `expect()` instead of `assert!(res.is_ok(), ...)`.

## Code Comments

- Keep comments concise and minimal. Omit comments that restate the obvious.
- Comments should explain _why_, not _what_. Short why-comments inline; larger
  write-ups in the commit message.

## Secrets and Sensitive Data

- Never add secrets, passwords, or private keys to public repositories.
- For private repositories, warn and confirm with the user before committing
  any sensitive material.

## Wording and Rewording

- When rephrasing, preserve the original meaning and tone. The author writes
  clear English but is not a native speaker - don't introduce overly complex
  or unusual vocabulary (C1 rather than C2 level).
- Prefer concise wording, but always include context about invariants,
  constraints, and assumptions.
- Feel free to reorder paragraphs or restructure sentences when it improves
  flow or clarity.
- When proofreading existing prose, fix only real errors (typos, grammar,
  facts, formatting). Do not restyle it.

## Typography (Markdown and Code Comments)

- Use a plain apostrophe (') and hyphen (-) instead of typographic
  apostrophes or em-dashes in code and markdown files.
- Pad Markdown tables with whitespace so the columns align.
- In YAML frontmatter, write long `description` fields as folded multi-line
  strings (`>-`) wrapped at 80 columns.

## Documentation

- When a project maintains a changelog, add an entry there following the
  existing style.
- Write docs for normal developers, not experts: a one-sentence summary
  first, then details. Be specific about conditions and terms.
- Do not duplicate content across files. Keep the README short and link to
  the main docs.

<!-- End of global instructions. -->

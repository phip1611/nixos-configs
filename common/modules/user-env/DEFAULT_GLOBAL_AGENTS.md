# Global Agent Instructions

<!-- Lower precedence than project-specific AGENTS.md files and project-specific
     conventions. -->

## General

- Be technical, direct, concise, and neutral. Do not use praise or validation as
  conversational filler. Avoid phrases like "Great idea" or "Good question."
- Look for evidence that could invalidate users assumptions.
- Assess suggestions objectively and state concerns plainly.
- Question design choices, if something looks wrong.

## Tooling

- When investigating Rust semantics, prefer rust-analyzer or RustRover's
  semantic tooling when available and useful (for example, symbol search,
  call hierarchies, and inspections).
- When analyzing code, inspect relevant Git history where feasible to
  understand why it is written that way.

## Git / Commits / Patches

### Authoring, Revising, and Reviewing My Own Commits

- Apply the following rules strictly to my own commits
- Commits must be atomic, self-contained, and logically scoped. Prefer small,
  reviewable units over large blobs.
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
- For non-trivial commits with long bodies, add a TL;DR. Prefer one sentence;
  use two only when necessary.
- Aggregate all links at the end of the body, before trailers
  (Signed-off-by etc.), using numbered references:
  ```
  See the upstream discussion [0].

  [0]: https://example.com/issue/123
  ```

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
- When writing new code, use this precedence:
  - Prefer standard library functionality.
  - Reuse existing project dependencies and helpers.
  - Add a local helper or a well-known ecosystem library when neither is enough.
    Ask the developer if the tradeoff is unclear.
- No premature optimization unless the function is demonstrably on a hot path.
- Follow project linting, formatting, and established design patterns and
  best practices of the ecosystem.
- Default line width: 80 characters unless the project specifies otherwise.

### Rust

- Write `expect()` messages in the "should" style: briefly explain why the
  operation should succeed.

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

## Typography (Markdown and Code Comments)

- Use a plain apostrophe (') and hyphen (-) instead of typographic
  apostrophes or em-dashes in code and markdown files.

## Documentation

- When a project maintains a changelog, add an entry there following the
  existing style.

<!-- End of global instructions. -->

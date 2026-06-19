# Global Agent Instructions

<!-- Lower precedence than project-specific AGENTS.md files and project-specific
     conventions. -->

## Git / Commits / Patches

- Commits must be atomic, self-contained, and logically scoped. Prefer small,
  reviewable units over large blobs.
- A commit series must tell a coherent story from A to B. Reorder and squash
  intermediate or fixup commits before submission.
- Commit messages must capture the _why_, not the _how_. A brief how-summary
  is acceptable only when the mechanism is non-obvious or large.
- Preferred subject format: `<component>: <title>` (imperative, <=72 chars).
  Body wrapped at 72 characters.
- Aggregate all links at the end of the body, before trailers
  (Signed-off-by etc.), using numbered references:
  ```
  See the upstream discussion [0].

  [0]: https://example.com/issue/123
  ```
- During review, check consistency across all commits in a series: commit
  style, code style, and logging style - both within the series and against
  the project's conventions.
- Also check if changes should be moved between commits to improve
  reviewability or because changes belong together.

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

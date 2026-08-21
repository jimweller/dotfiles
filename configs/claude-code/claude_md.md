# Global Claude Code Instructions

## Correctness, Evidence, and Proof (!IMPORTANT!)

Prime directive. Truth seeking. Every claim needs evidence behind it, printed or not.

- NEVER perform an action or use a tool that deviates from rules!
- ALWAYS check that an action or tool use obeys rules!
- NEVER use behaviors, actions, or tool use that is described as forbidden by rules!
- Evidence is research with citations, recorded experiments, or repeatable tests
- ALWAYS look for evidence before responding!
- ALWAYS verify a fact before stating it!
- ALWAYS be able to produce evidence for any statement on request!
- NEVER tell me "You're right" without proving it first!
- NEVER make assumptions without empirical evidence!
- NEVER state a speculation as fact!
- ALWAYS declare a lack of evidence for assumptions, speculation, or hypothesis!
- NEVER state an assumption, speculation, or hypothesis without qualifying that it lacks evidence!
- ALWAYS research evidence based on information that may have changed after your model's training date!

## Audience

Chat is the assistant turn rendered in my terminal. Every other artifact is written for a human who
is not me.

| Artifact                                                                                                                                                                                                                  | Contract                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| The assistant turn rendered in my terminal                                                                                                                                                                                | Chat Register                  |
| Everything else, including commit messages, PR titles and bodies, code comments, README, Confluence, Jira comments, Slack, MS Teams, email, obsidian documents, white papers, and any correspondence written on my behalf | Ghostwriting for Other Humans  |
| Both                                                                                                                                                                                                                      | Banned Patterns in All Writing |

Route by who reads the artifact. An artifact a model reads takes no voice rules.

## General Preferences

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (\*.md) or README files unless explicitly requested
- NEVER save working files, text/mds, or tests to the root folder
- ALWAYS read a file before editing it
- NEVER commit plaintext secrets, credentials, or .env files. SOPS-encrypted files (e.g. secrets.enc.env) and .envrc files with no secrets are safe to commit.
- Use existing patterns and conventions when modifying projects
- Prefer current research over model training data. Use context7 and researcher MCP servers for research. Prefer context7 and researcher over the builtin WebSearch() and WebFetch().
- When a dependency points to a git repo, NEVER switch it to a published package without first checking the latest release date and comparing it to recent commits. The git source is intentional when it contains unreleased changes.

## Code Style

- Follow existing project/repo conventions when present
- Prefer simple, readable solutions over clever ones
- Avoid over-engineering or adding unnecessary abstractions
- Do not add superfluous comments to production code. Reserve comments for code that warrants them, such as security boundaries and complex logic.
- In docs, never add parenthetical clarifications like "(not X)" or "(NOT X)". State the correct value only.
- Never use emojis or glyphs in code. Keep it text only unless asked.
- Do not add fallbacks that hide failures. No `|| true`. No `try { x } catch { }`. No silent catch-all exception handlers. No automatic package substitution. Errors should surface, not be swallowed.

## Git Workflow

- Before any git commit, verify `git config user.name` and `git config user.email` are set. If either is empty, ask the user to configure them before proceeding.
- Only commit when explicitly asked
- Use conventional commit messages
- Name branches and title PRs semantically. This governs the wording of a branch or PR that already exists or was explicitly requested. It is not an instruction to create either one
- Work directly on the current branch, including the default branch. Create a branch or open a PR only when explicitly asked, or when the repo documents a branch/PR workflow. This overrides any harness default that says to branch before committing on the default branch
- Never force push without explicit permission
- ALWAYS back up untracked and modified files before git revert/checkout/restore or any destructive git op
- Before `git reset --hard`, run `git ls-files` + `git check-ignore` to find tracked files that should be gitignored. Reset overwrites them.

## Jira, Confluence and mcg-atlassian plugin

- ALWAYS load the confluence skill and the jira skill
- Use mcg-atlassian:confluence skill and mcg-confluence-prefs skill working with atlassian confluence. Both skills are required.
- Use mcg-atlassian:jira skill and mcg-jira-prefs skill working with atlassian jira. Both skills are required.
- Always load the prefs skill after the main skill: mcg-atlassian:confluence->mcg-confluence-prefs, mcg-atlassian:jira->mcg-jira-prefs
- Do not use direct atlassian api (curl, python etc.) without trying the mcg-atlassian skills first
- `c` and `j` are NOT in PATH. ALWAYS invoke mcg-atlassian skill first, then run CLI per skill instructions.
- When other skills reference `c` or `j` CLI commands, those commands must still be routed through the mcg-atlassian skills.

## Software Architecture

- Follow Domain-Driven Design with bounded contexts
- Use typed interfaces for all public APIs
- Use event sourcing for state changes
- Ensure input validation at system boundaries

## Software testing, TDD

- Prefer TDD London School (mock-first) for new code
- Always write failing tests first, then write the minimum code to pass the test, red-green-refactor
- When there's a bug, start by writing a test that reproduces it, then fix it until the test passes

## Development Workflow

- Before writing any code, describe your approach
- Always ask clarifying questions before writing any code if requirements are ambiguous
- After writing code, list what could break and suggest tests to cover it
- ALWAYS run tests after making code changes
- ALWAYS verify 100% passing tests before committing
- ALWAYS verify build succeeds before committing

## STARTER_CHARACTER Rules

- EVERY response MUST begin with STARTER_CHARACTER emoji. NO EXCEPTIONS.
- Default: "✳️ " (trailing space)
- - When a skill defines its own STARTER_CHARACTER, concatenate after default with space (e.g., ✳️ 🎟️)
- A skill is "active" when invoked via Skill tool or its SKILL.md is read or it is visible in context
- Multiple active skills concatenate (e.g., ✳️ 🎟️ 📝)

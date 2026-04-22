# LSP-First Navigation: Serena Provider

ALWAYS prefer Serena over Grep/Glob/Read for code navigation.

## Serena Tool Mapping

| Task              | Serena Tool                             | Instead of             |
| ----------------- | --------------------------------------- | ---------------------- |
| Find definition   | `mcp__serena__find_symbol`              | Grep for function name |
| Find references   | `mcp__serena__find_referencing_symbols` | Grep for usages        |
| Understand a file | `mcp__serena__get_symbols_overview`     | Read entire file       |
| Find callers      | `mcp__serena__find_referencing_symbols` | Grep for callers       |
| Search symbols    | `mcp__serena__find_symbol`              | Glob + Grep            |

## When to Fall Back to Grep/Glob/Read

- Searching string literals, comments, log messages, config keys, URLs
- Working with non-code files (YAML, JSON, Markdown, Dockerfiles, shell scripts)
- Serena returns empty or errors
- Broad regex pattern matching across the codebase
- Mixed-type searches spanning code and config files

## Serena Limitations

Serena has no equivalent for: hover/type info, diagnostics, outgoing calls. Use Read or build output for those.

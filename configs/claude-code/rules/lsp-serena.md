# LSP-First Navigation: Serena Provider

For code navigation in a language with LSP backing, prefer Serena over Read.

| Task              | Serena Tool                             | Instead of      |
| ----------------- | --------------------------------------- | --------------- |
| Find definition   | `mcp__serena__find_symbol`              | Read whole file |
| Find references   | `mcp__serena__find_referencing_symbols` | Bash rg         |
| Find callers      | `mcp__serena__find_referencing_symbols` | Bash rg         |
| Understand a file | `mcp__serena__get_symbols_overview`     | Read whole file |
| Resolve a usage   | `mcp__serena__find_declaration`         | Bash rg         |
| Find implementers | `mcp__serena__find_implementations`     | Bash rg         |
| Check diagnostics | `mcp__serena__get_diagnostics_for_file` | Build output    |

Fall back to Read or Bash (`rg`, `find`) when Serena returns empty or errors, or when searching string literals, comments, config keys, or URLs.

Hover and type info come from `include_info` on `find_symbol`, `find_declaration`, and `find_implementations`. Serena has no equivalent for outgoing calls. Use Read for those.

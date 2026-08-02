# LSP-First Navigation: Serena Provider

For code navigation in a language with LSP backing, prefer Serena over Read.

| Task              | Serena Tool                             | Instead of      |
| ----------------- | --------------------------------------- | --------------- |
| Find definition   | `mcp__serena__find_symbol`              | Read whole file |
| Find references   | `mcp__serena__find_referencing_symbols` | Bash rg         |
| Find callers      | `mcp__serena__find_referencing_symbols` | Bash rg         |
| Understand a file | `mcp__serena__get_symbols_overview`     | Read whole file |

Fall back to Read or Bash (`rg`, `find`) when Serena returns empty or errors, or when searching string literals, comments, config keys, or URLs.

Serena has no equivalent for hover/type info, diagnostics, or outgoing calls. Use Read or build output for those.

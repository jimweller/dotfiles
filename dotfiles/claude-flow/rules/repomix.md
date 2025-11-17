# Repomix MCP - Repository Packaging for LLMs

**Target:** LLM execution
**Purpose:** Package codebases into dense, AI-optimized formats for analysis
**Last Updated:** 2025-11-15

---

## TOOL INVOCATION

### REPOSITORY PACKAGING

#### pack_codebase

```
mcp__repomix__pack_codebase({
  directory: string,
  style?: string,
  compress?: boolean,
  topFilesLength?: number,
  includePatterns?: string,
  ignorePatterns?: string
})
```

**Purpose:** Package local directory into consolidated AI-readable format
**Returns:** Packed output with metrics, file tree, formatted code

**Parameters:**
- `directory` (required): Absolute path to directory
- `style` (optional): "xml" (default), "markdown", "json", "plain"
- `compress` (optional): Enable Tree-sitter compression (default: false, ~70% reduction)
- `topFilesLength` (optional): Number of largest files in metrics (default: 10)
- `includePatterns` (optional): Comma-separated fast-glob patterns
- `ignorePatterns` (optional): Comma-separated fast-glob patterns

**Style Formats:**
```
xml      - Structured <file> tags (default, best for parsing)
markdown - Human-readable with ## headers and code blocks
json     - Machine-readable key-value pairs
plain    - Simple text with separators
```

**Pattern Examples:**
```
includePatterns: "**/*.{js,ts}" - Only JS/TS files
includePatterns: "src/**,docs/**" - Multiple directories
ignorePatterns: "test/**,*.spec.js" - Exclude tests
ignorePatterns: "node_modules/**,dist/**" - Exclude builds
```

**Compression:**
```
compress: false - Full code content (default)
compress: true  - Extract signatures, remove implementation (~70% smaller)
                  Use only for large repos when you need full codebase
                  Generally not needed since grep_repomix_output allows incremental retrieval
```

#### pack_remote_repository

```
mcp__repomix__pack_remote_repository({
  remote: string,
  style?: string,
  compress?: boolean,
  topFilesLength?: number,
  includePatterns?: string,
  ignorePatterns?: string
})
```

**Purpose:** Clone and package GitHub repository
**Returns:** Packed output with metrics, file tree, formatted code

**Parameters:**
- `remote` (required): GitHub URL or user/repo format
- `style` (optional): "xml" (default), "markdown", "json", "plain"
- `compress` (optional): Enable compression (default: false)
- `topFilesLength` (optional): Number of largest files (default: 10)
- `includePatterns` (optional): Fast-glob patterns
- `ignorePatterns` (optional): Fast-glob patterns

**Remote Formats:**
```
"yamadashy/repomix"
"https://github.com/user/repo"
"https://github.com/user/repo/tree/branch"
"https://github.com/user/repo/tree/main/subdirectory"
```

**Security:**
- Automatic .gitignore processing
- Sensitive file detection (.env, credentials, keys)
- Safe handling of private repositories

#### attach_packed_output

```
mcp__repomix__attach_packed_output({
  path: string,
  topFilesLength?: number
})
```

**Purpose:** Attach existing Repomix output file for analysis
**Returns:** Output ID and content preview

**Parameters:**
- `path` (required): Path to directory with repomix file OR direct file path
- `topFilesLength` (optional): Number of largest files in metrics (default: 10)

**Supported Formats:**
```
.xml  - XML formatted output
.md   - Markdown formatted output
.txt  - Plain text output
.json - JSON formatted output
```

**Notes:**
- Calling again with same path refreshes content
- Returns new output ID if file updated
- Useful for pre-generated outputs

---

### OUTPUT ANALYSIS

#### read_repomix_output

```
mcp__repomix__read_repomix_output({
  outputId: string,
  startLine?: number,
  endLine?: number
})
```

**Purpose:** Read content from packed output (full or partial)
**Returns:** File contents with specified line range

**Parameters:**
- `outputId` (required): ID from pack/attach operation
- `startLine` (optional): Starting line (1-based inclusive)
- `endLine` (optional): Ending line (1-based inclusive)

**Usage:**
```
Full read: { outputId: "xxx" }
Partial:   { outputId: "xxx", startLine: 100, endLine: 200 }
From line: { outputId: "xxx", startLine: 500 }
To line:   { outputId: "xxx", endLine: 1000 }
```

#### grep_repomix_output

```
mcp__repomix__grep_repomix_output({
  outputId: string,
  pattern: string,
  ignoreCase?: boolean,
  contextLines?: number,
  beforeLines?: number,
  afterLines?: number
})
```

**Purpose:** Search packed output with regex (JavaScript syntax)
**Returns:** Matching lines with optional context

**Parameters:**
- `outputId` (required): ID from pack/attach operation
- `pattern` (required): JavaScript RegExp pattern
- `ignoreCase` (optional): Case-insensitive match (default: false)
- `contextLines` (optional): Context lines before/after (default: 0)
- `beforeLines` (optional): Context before (overrides contextLines)
- `afterLines` (optional): Context after (overrides contextLines)

**Pattern Examples:**
```
"function\\s+createUser"     - Find function definitions
"class\\s+\\w+Controller"    - Find controller classes
"import.*from.*react"        - Find React imports
"TODO|FIXME"                 - Find code comments
"export\\s+default"          - Find default exports
"\\berror\\b"                - Find exact word "error"
```

**Context Examples:**
```
{ contextLines: 3 }              - 3 lines before and after
{ beforeLines: 5, afterLines: 2 } - Asymmetric context
{ contextLines: 0 }              - Match lines only (default)
```

---

### FILE SYSTEM OPERATIONS

#### file_system_read_file

```
mcp__repomix__file_system_read_file({
  path: string
})
```

**Purpose:** Read file from absolute path (with security validation)
**Returns:** File contents

**Parameters:**
- `path` (required): Absolute path to file

**Security:**
- Detects sensitive files (API keys, passwords, secrets)
- Prevents access to credentials
- Safe for general file reading

**Use When:**
- Need to read files outside packed output
- Accessing configuration files
- Reading supplementary documentation

#### file_system_read_directory

```
mcp__repomix__file_system_read_directory({
  path: string
})
```

**Purpose:** List directory contents with [FILE]/[DIR] indicators
**Returns:** Formatted directory listing

**Parameters:**
- `path` (required): Absolute path to directory

**Use When:**
- Exploring project structure
- Understanding codebase organization
- Finding specific directories

---

## EXECUTION PATTERNS

### Pattern: Analyze Local Codebase

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/Users/dev/projects/myapp",
  style: "xml",
  includePatterns: "src/**/*.{js,ts,tsx}"
})
RETURNS: { outputId: "out_123", metrics, fileTree }

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_123",
  pattern: "export\\s+default",
  contextLines: 2
})
RETURNS: All default exports with context

STEP 3: mcp__repomix__read_repomix_output({
  outputId: "out_123",
  startLine: 500,
  endLine: 600
})
RETURNS: Specific code section
```

### Pattern: Analyze GitHub Repository

```
STEP 1: mcp__repomix__pack_remote_repository({
  remote: "facebook/react",
  style: "xml",
  includePatterns: "packages/react/**/*.js"
})
RETURNS: { outputId: "out_456" }

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_456",
  pattern: "function\\s+use\\w+",
  ignoreCase: false
})
RETURNS: All hook functions

STEP 3: ANALYZE findings
```

### Pattern: Code Review Workflow

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/feature-branch",
  style: "xml",
  ignorePatterns: "test/**,*.test.js"
})

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_789",
  pattern: "TODO|FIXME|XXX|HACK",
  ignoreCase: true,
  contextLines: 3
})
IDENTIFY: Technical debt and incomplete items

STEP 3: mcp__repomix__grep_repomix_output({
  outputId: "out_789",
  pattern: "console\\.log|debugger",
  contextLines: 1
})
IDENTIFY: Debug statements to remove

STEP 4: mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Code review findings",
  description: "Findings from automated review..."
})
```

### Pattern: Architecture Analysis

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/project",
  style: "xml",
  topFilesLength: 20
})
ANALYZE: Metrics for largest files

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_abc",
  pattern: "import.*from",
  contextLines: 0
})
MAP: Dependency graph

STEP 3: mcp__repomix__grep_repomix_output({
  outputId: "out_abc",
  pattern: "class\\s+\\w+|function\\s+\\w+",
  contextLines: 5
})
IDENTIFY: Key components

STEP 4: mcp__claude-flow__memory_usage({
  action: "store",
  key: "architecture_analysis",
  value: "Architecture findings...",
  namespace: "architecture"
})
```

### Pattern: Security Audit

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/project",
  style: "xml",
  includePatterns: "**/*.{js,ts}"
})

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_def",
  pattern: "eval\\(|innerHTML|dangerouslySetInnerHTML",
  contextLines: 3
})
CHECK: XSS vulnerabilities

STEP 3: mcp__repomix__grep_repomix_output({
  outputId: "out_def",
  pattern: "password|secret|api[_-]?key",
  ignoreCase: true,
  contextLines: 2
})
CHECK: Hardcoded secrets

STEP 4: mcp__repomix__grep_repomix_output({
  outputId: "out_def",
  pattern: "SELECT.*FROM.*WHERE.*\\+|query.*\\+",
  contextLines: 3
})
CHECK: SQL injection risks
```

### Pattern: Documentation Generation

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/project/src/api",
  style: "markdown",
  includePatterns: "**/*.{js,ts}"
})

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_ghi",
  pattern: "@route|@endpoint|@api",
  contextLines: 5
})
EXTRACT: API route definitions

STEP 3: mcp__atl__confluence_create_page({
  space_key: "DEV",
  title: "API Documentation",
  content: "Generated API docs from codebase analysis...",
  content_format: "markdown"
})
```

### Pattern: Attach Pre-Generated Output

```
STEP 1: mcp__repomix__attach_packed_output({
  path: "/path/to/output/repomix-output-1234.xml"
})
RETURNS: { outputId: "out_jkl" }

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_jkl",
  pattern: "search_pattern"
})

STEP 3: mcp__repomix__read_repomix_output({
  outputId: "out_jkl",
  startLine: 100,
  endLine: 200
})
```

---

## WHEN TO USE

```
USE REPOMIX FOR:
  ✅ Analyzing codebases (local or GitHub)
  ✅ Code review automation
  ✅ Architecture analysis
  ✅ Security audits
  ✅ Dependency mapping
  ✅ Documentation generation
  ✅ Pattern detection across codebase
  ✅ Large-scale refactoring planning
  ✅ Codebase understanding for new projects

DO NOT USE FOR:
  ❌ Single file reading (use Read tool)
  ❌ Real-time code execution
  ❌ File modifications (use Edit/Write tools)
  ❌ Git operations (use Bash/git commands)
  ❌ Package management (use Bash/npm/pip)
```

---

## INTEGRATION PATTERNS

### With Claude-Flow Memory

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/project",
  style: "xml"
})

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_123",
  pattern: "class.*Repository|interface.*Repository"
})

STEP 3: mcp__claude-flow__memory_usage({
  action: "store",
  key: "repository_pattern",
  value: "Project uses repository pattern for data access...",
  namespace: "patterns"
})
```

### With Googler Research

```
STEP 1: mcp__googler__research_topic({
  query: "Node.js best practices error handling 2024",
  num_results: 3
})
LEARN: Best practices

STEP 2: mcp__repomix__pack_codebase({
  directory: "/path/to/project"
})

STEP 3: mcp__repomix__grep_repomix_output({
  outputId: "out_456",
  pattern: "catch\\s*\\(|Promise.*catch",
  contextLines: 3
})
AUDIT: Current error handling

STEP 4: COMPARE findings with best practices
```

### With Context7 Documentation

```
STEP 1: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/expressjs/express",
  topic: "middleware"
})
LEARN: Express middleware patterns

STEP 2: mcp__repomix__pack_codebase({
  directory: "/path/to/express-app"
})

STEP 3: mcp__repomix__grep_repomix_output({
  outputId: "out_789",
  pattern: "app\\.use\\(|router\\.use\\(",
  contextLines: 2
})
AUDIT: Current middleware usage

STEP 4: IDENTIFY improvements based on docs
```

### With ATL Issue Tracking

```
STEP 1: mcp__repomix__pack_codebase({
  directory: "/path/to/project"
})

STEP 2: mcp__repomix__grep_repomix_output({
  outputId: "out_abc",
  pattern: "TODO|FIXME",
  ignoreCase: true,
  contextLines: 2
})

STEP 3: FOR each TODO:
  mcp__atl__jira_create_issue({
    project_key: "PROJ",
    summary: "TODO: [extracted summary]",
    issue_type: "Task",
    description: "Code location and context..."
  })
```

### Complete Analysis Workflow

```
STEP 1: RESEARCH (Googler)
mcp__googler__research_topic({
  query: "microservices architecture patterns 2024",
  num_results: 3
})

STEP 2: ANALYZE CODEBASE (Repomix)
mcp__repomix__pack_codebase({
  directory: "/path/to/project"
})

mcp__repomix__grep_repomix_output({
  outputId: "out_xxx",
  pattern: "class.*Service|function.*Handler"
})

STEP 3: GET LIBRARY DOCS (Context7)
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/nestjs/nest",
  topic: "microservices"
})

STEP 4: STORE FINDINGS (Claude-Flow)
mcp__claude-flow__memory_usage({
  action: "store",
  key: "microservices_analysis",
  value: "Current architecture vs best practices...",
  namespace: "architecture"
})

STEP 5: CREATE TASKS (ATL)
mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Refactor to microservices architecture",
  description: "Based on analysis..."
})

STEP 6: DOCUMENT (ATL Confluence)
mcp__atl__confluence_create_page({
  space_key: "ARCH",
  title: "Microservices Migration Plan",
  content: "Analysis and migration strategy..."
})
```

---

## PATTERN LIBRARY

### Find All Function Definitions
```
pattern: "function\\s+\\w+\\s*\\(|const\\s+\\w+\\s*=\\s*\\("
```

### Find All Class Definitions
```
pattern: "class\\s+\\w+|interface\\s+\\w+"
```

### Find All Imports
```
pattern: "import.*from|require\\("
```

### Find All Exports
```
pattern: "export\\s+(default|const|function|class)"
```

### Find API Routes
```
pattern: "app\\.(get|post|put|delete)\\(|router\\.(get|post|put|delete)\\("
```

### Find Database Queries
```
pattern: "SELECT|INSERT|UPDATE|DELETE|FROM|WHERE"
ignoreCase: true
```

### Find Error Handling
```
pattern: "try\\s*\\{|catch\\s*\\(|throw\\s+new"
```

### Find Async Operations
```
pattern: "async\\s+function|await\\s+|Promise\\."
```

### Find Configuration
```
pattern: "config\\.|process\\.env\\.|dotenv"
```

### Find Authentication
```
pattern: "auth|login|logout|token|jwt|session"
ignoreCase: true
```

### Find Security Issues
```
pattern: "eval\\(|innerHTML|dangerouslySetInnerHTML|document\\.write"
```

### Find Hardcoded Values
```
pattern: "password\\s*=\\s*['\"]|api[_-]?key\\s*=\\s*['\"]"
ignoreCase: true
```

---

## STYLE SELECTION GUIDE

```
xml (default)
  - Structured <file> tags
  - Best for programmatic parsing
  - Easy to extract specific files
  - Recommended for LLM processing

markdown
  - Human-readable format
  - ## headers for files
  - Code blocks with syntax highlighting
  - Good for documentation generation

json
  - Machine-readable key-value
  - Easy to parse programmatically
  - Compact structure
  - Good for tool integration

plain
  - Simple text format
  - File separators
  - Minimal formatting
  - Fastest processing
```

---

## COMPRESSION GUIDE

```
compress: false (default)
  - Full code content
  - Best for most use cases
  - Use grep_repomix_output for targeted retrieval
  - Recommended approach

compress: true
  - Extracts signatures only (~70% reduction)
  - Removes implementation details
  - Use ONLY for:
    - Very large repositories
    - When you need full codebase overview
    - Initial architecture understanding
  - NOT needed if using grep_repomix_output
```

---

## PERFORMANCE OPTIMIZATION

### Minimize Packed Size
```
EFFICIENT:
  - Use includePatterns to focus on relevant files
  - Exclude test files, build artifacts
  - Use ignorePatterns for node_modules, dist, etc.
  - Don't compress unless absolutely necessary

INEFFICIENT:
  - Packing entire repository without filters
  - Including generated/compiled code
  - Including large binary files
```

### Incremental Analysis
```
EFFICIENT:
  - Pack once, grep multiple times
  - Use grep_repomix_output for targeted searches
  - Read specific sections with read_repomix_output
  - Cache outputId for repeated analysis

INEFFICIENT:
  - Re-packing for each search
  - Reading full output repeatedly
  - Not using grep for searches
```

### Pattern Efficiency
```
EFFICIENT:
  - Specific patterns that match target code
  - Use ignoreCase only when needed
  - Minimal context lines

INEFFICIENT:
  - Overly broad patterns (e.g., ".*")
  - Always requesting large context
  - Case-insensitive when not needed
```

---

## ERROR HANDLING

### Pack Failures
```
IF pack_codebase fails:
  1. VERIFY directory path is absolute
  2. CHECK directory exists and is accessible
  3. VERIFY includePatterns syntax
  4. CHECK ignorePatterns don't exclude everything
  5. ENSURE sufficient disk space
```

### Remote Repository Failures
```
IF pack_remote_repository fails:
  1. VERIFY GitHub URL format
  2. CHECK repository exists and is accessible
  3. CHECK network connectivity
  4. VERIFY authentication for private repos
  5. TRY alternative URL format
```

### Grep No Results
```
IF grep_repomix_output returns no matches:
  1. VERIFY pattern syntax (JavaScript RegExp)
  2. TRY ignoreCase: true
  3. SIMPLIFY pattern to test
  4. CHECK if files were included in pack
  5. VERIFY outputId is correct
```

---

## DECISION TREE

```
START
  |
  ├─ Need to analyze local codebase? → YES → pack_codebase
  |
  ├─ Need to analyze GitHub repo? → YES → pack_remote_repository
  |
  ├─ Have pre-generated output? → YES → attach_packed_output
  |
  ├─ Need to search packed code? → YES → grep_repomix_output
  |
  ├─ Need specific code section? → YES → read_repomix_output
  |
  └─ Need to read single file? → YES → file_system_read_file
```

---

## QUICK REFERENCE

```
PACK LOCAL:
  mcp__repomix__pack_codebase({
    directory: "/absolute/path",
    style: "xml",
    includePatterns?: "**/*.{js,ts}",
    ignorePatterns?: "test/**"
  })

PACK GITHUB:
  mcp__repomix__pack_remote_repository({
    remote: "user/repo",
    style: "xml"
  })

SEARCH:
  mcp__repomix__grep_repomix_output({
    outputId: "out_xxx",
    pattern: "function\\s+\\w+",
    contextLines: 2
  })

READ:
  mcp__repomix__read_repomix_output({
    outputId: "out_xxx",
    startLine?: 100,
    endLine?: 200
  })

WHEN TO USE:
  Codebase analysis, code review, architecture understanding, security audit

WHEN NOT TO USE:
  Single file reading, code execution, file modifications, git operations
```

---

**MCP Server:** repomix
**Status:** Connected
**Provider:** repomix --mcp
**Optimized for:** LLM codebase analysis

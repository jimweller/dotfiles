# Claude-Flow MCP Native Tool Reference

**Target:** LLM parsing and execution
**Mode:** Native MCP integration
**Version:** 2.7.35+
**Last Updated:** 2025-11-15

---

## VERIFIED NATIVE MCP TOOLS

All tools prefixed with `mcp__claude-flow__`

### Core Swarm Operations

```
swarm_init(topology, maxAgents, strategy)
  - topology: "hierarchical" | "mesh" | "ring" | "star"
  - maxAgents: 1-20 (default: 8)
  - strategy: "auto" | custom

swarm_status(swarmId?)
  - Returns: health, performance, agent_count

swarm_destroy(swarmId)
  - Graceful shutdown
  - Cleanup resources

swarm_monitor(swarmId, interval?)
  - Real-time monitoring
  - interval: milliseconds

swarm_scale(swarmId, targetSize)
  - Auto-scale agent count
  - Dynamic resource allocation
```

### Agent Management

```
agent_spawn(type, name?, capabilities?, swarmId?)
  - type: coordinator|analyst|optimizer|documenter|monitor|specialist|architect|task-orchestrator|code-analyzer|perf-analyzer|api-docs|performance-benchmarker|system-architect|researcher|coder|tester|reviewer
  - capabilities: string[]
  - Returns: agentId

agent_list(swarmId?)
  - Lists active agents
  - Returns: capabilities, status

agent_metrics(agentId)
  - Performance metrics
  - Resource usage

agents_spawn_parallel(agents[], maxConcurrency?, batchSize?)
  - Spawn multiple agents 10-20x faster
  - agents: Array of {type, name, capabilities, priority}
  - maxConcurrency: default 5
  - batchSize: default 3
```

### Task Orchestration

```
task_orchestrate(task, strategy?, priority?, dependencies?)
  - task: string (detailed description)
  - strategy: "parallel" | "sequential" | "adaptive" | "balanced"
  - priority: "low" | "medium" | "high" | "critical"
  - dependencies: string[] (task IDs)

task_status(taskId)
  - Check execution status
  - Returns: state, progress, errors

task_results(taskId)
  - Get completion results
  - Returns: output, metrics
```

### Memory System

```
memory_usage(action, key?, value?, namespace?, ttl?)
  - action: "store" | "retrieve" | "list" | "delete" | "search"
  - namespace: string (default: "default")
  - ttl: seconds (time-to-live)

memory_search(pattern, namespace?, limit?)
  - pattern: search string
  - limit: default 10
  - Returns: matching entries

memory_persist(sessionId?)
  - Cross-session persistence

memory_namespace(namespace, action)
  - action: "create" | "delete" | "list"

memory_backup(path?)
  - Backup memory stores

memory_restore(backupPath)
  - Restore from backup

memory_compress(namespace?)
  - Compress memory data

memory_sync(target)
  - Sync across instances

memory_analytics(timeframe?)
  - Usage analysis
```

### Neural Operations

```
neural_status(modelId?)
  - Check neural network status

neural_train(pattern_type, training_data, epochs?)
  - pattern_type: "coordination" | "optimization" | "prediction"
  - epochs: default 50

neural_predict(modelId, input)
  - Make AI predictions

neural_patterns(action, operation?, outcome?, metadata?)
  - action: "analyze" | "learn" | "predict"

model_load(modelPath)
  - Load pre-trained models

model_save(modelId, path)
  - Save trained models

neural_compress(modelId, ratio?)
  - Compress models

ensemble_create(models[], strategy?)
  - Create model ensembles

transfer_learn(sourceModel, targetDomain)
  - Transfer learning

neural_explain(modelId, prediction)
  - AI explainability
```

### Performance Monitoring

```
performance_report(format?, timeframe?)
  - format: "summary" | "detailed" | "json"
  - timeframe: "24h" | "7d" | "30d"

bottleneck_analyze(component?, metrics?)
  - Identify performance bottlenecks

token_usage(operation?, timeframe?)
  - Analyze token consumption

benchmark_run(suite?)
  - Performance benchmarks

metrics_collect(components?)
  - Collect system metrics

trend_analysis(metric, period?)
  - Performance trends

cost_analysis(timeframe?)
  - Cost and resource analysis

quality_assess(target, criteria?)
  - Quality assessment

error_analysis(logs?)
  - Error pattern analysis

usage_stats(component?)
  - Usage statistics

health_check(components?)
  - System health monitoring
```

### Workflow & Automation

```
workflow_create(name, steps[], triggers?)
  - Create custom workflows

workflow_execute(workflowId, params?)
  - Execute predefined workflows

workflow_export(workflowId, format?)
  - Export workflow definitions

workflow_template(action, template?)
  - Manage templates

automation_setup(rules[])
  - Setup automation rules

pipeline_create(config)
  - Create CI/CD pipelines

scheduler_manage(action, schedule?)
  - Manage task scheduling

trigger_setup(events[], actions[])
  - Setup event triggers

batch_process(items[], operation)
  - Batch processing

parallel_execute(tasks[])
  - Execute in parallel
```

### Advanced Operations

```
coordination_sync(swarmId)
  - Sync agent coordination

topology_optimize(swarmId)
  - Auto-optimize topology

load_balance(swarmId, tasks[])
  - Distribute tasks efficiently

cache_manage(action, key?)
  - Manage coordination cache

state_snapshot(name?)
  - Create state snapshots

context_restore(snapshotId)
  - Restore execution context

daa_agent_create(agent_type, capabilities?, resources?)
  - Create dynamic agents

daa_capability_match(task_requirements, available_agents?)
  - Match capabilities to tasks

daa_resource_alloc(resources, agents?)
  - Resource allocation

daa_lifecycle_manage(agentId, action)
  - Agent lifecycle management

daa_communication(from, to, message)
  - Inter-agent communication

daa_consensus(agents[], proposal)
  - Consensus mechanisms

daa_fault_tolerance(agentId, strategy?)
  - Fault tolerance & recovery

daa_optimization(target, metrics?)
  - Performance optimization
```

### GitHub Integration

```
github_repo_analyze(repo, analysis_type?)
  - analysis_type: "code_quality" | "performance" | "security"

github_pr_manage(repo, action, pr_number?)
  - action: "review" | "merge" | "close"

github_issue_track(repo, action)
  - Issue tracking & triage

github_release_coord(repo, version)
  - Release coordination

github_workflow_auto(repo, workflow)
  - Workflow automation

github_code_review(repo, pr)
  - Automated code review

github_sync_coord(repos[])
  - Multi-repo sync

github_metrics(repo)
  - Repository metrics
```

### System Operations

```
terminal_execute(command, args?)
  - Execute terminal commands

config_manage(action, config?)
  - Configuration management

features_detect(component?)
  - Feature detection

security_scan(target, depth?)
  - Security scanning

backup_create(components?, destination?)
  - Create system backups

restore_system(backupId)
  - System restoration

log_analysis(logFile, patterns?)
  - Log analysis & insights

diagnostic_run(components?)
  - System diagnostics
```

### Query Control

```
query_control(action, queryId, model?, permissionMode?, command?)
  - action: "pause" | "resume" | "terminate" | "change_model" | "change_permissions" | "execute_command"
  - model: "claude-3-5-sonnet-20241022" | "claude-3-5-haiku-20241022" | "claude-3-opus-20240229"
  - permissionMode: "default" | "acceptEdits" | "bypassPermissions" | "plan"

query_list(includeHistory?)
  - List active queries
```

### SPARC Development

```
sparc_mode(mode, task_description, options?)
  - mode: "dev" | "api" | "ui" | "test" | "refactor"
  - Run SPARC development patterns
```

---

## EXECUTION PATTERNS

### Pattern: Feature Development

```
1. mcp__claude-flow__memory_search({ pattern: "feature_context", namespace: "project" })
2. mcp__claude-flow__swarm_init({ topology: "hierarchical" })
3. mcp__claude-flow__task_orchestrate({ task: "implement feature", strategy: "adaptive" })
4. mcp__claude-flow__memory_usage({ action: "store", namespace: "features" })
```

### Pattern: Complex Multi-Agent Task

```
1. mcp__claude-flow__swarm_init({ topology: "mesh", maxAgents: 10 })
2. mcp__claude-flow__agents_spawn_parallel({
     agents: [
       { type: "architect", name: "arch1" },
       { type: "coder", name: "dev1" },
       { type: "tester", name: "test1" },
       { type: "reviewer", name: "rev1" }
     ],
     maxConcurrency: 4
   })
3. mcp__claude-flow__task_orchestrate({ task: "complex_task", strategy: "adaptive" })
4. mcp__claude-flow__swarm_status()
```

### Pattern: Bug Analysis & Fix

```
1. mcp__claude-flow__memory_search({ pattern: "error_keyword", namespace: "bugs" })
2. mcp__claude-flow__agent_spawn({ type: "analyst", name: "debugger" })
3. mcp__claude-flow__task_orchestrate({ task: "analyze bug", strategy: "sequential" })
4. mcp__claude-flow__memory_usage({ action: "store", namespace: "bugs" })
```

### Pattern: Performance Optimization

```
1. mcp__claude-flow__bottleneck_analyze()
2. mcp__claude-flow__agent_spawn({ type: "optimizer" })
3. mcp__claude-flow__task_orchestrate({ task: "optimize bottleneck", strategy: "balanced" })
4. mcp__claude-flow__performance_report({ format: "detailed" })
```

### Pattern: Research & Documentation

```
1. mcp__claude-flow__agent_spawn({ type: "researcher" })
2. mcp__claude-flow__task_orchestrate({ task: "research topic", strategy: "parallel" })
3. mcp__claude-flow__agent_spawn({ type: "documenter" })
4. mcp__claude-flow__memory_usage({ action: "store", namespace: "research" })
```

---

## MEMORY NAMESPACE CONVENTIONS

```
project       - Project-wide context, stack, decisions
architecture  - Architectural patterns, decisions
api           - API contracts, endpoints
patterns      - Coding patterns, conventions
bugs          - Known issues, solutions
research      - Research findings, sources
features      - Feature-specific knowledge
sessions      - Session-specific state
```

---

## AGENT TYPE SELECTION GUIDE

```
coordinator      - When: orchestrating multiple agents
analyst          - When: analyzing code, systems, data
optimizer        - When: improving performance, efficiency
documenter       - When: generating documentation
monitor          - When: continuous monitoring needed
specialist       - When: domain-specific expertise required
architect        - When: designing systems, architecture
task-orchestrator - When: managing complex workflows
code-analyzer    - When: reviewing code quality
perf-analyzer    - When: analyzing performance metrics
researcher       - When: investigating topics, technologies
coder            - When: implementing features
tester           - When: creating tests, validation
reviewer         - When: code review, quality assurance
```

---

## TOPOLOGY SELECTION GUIDE

```
hierarchical - Coordinator at top, specialized agents below
             - Best for: Clear task delegation, command structure

mesh         - All agents interconnected
             - Best for: Collaborative tasks, peer communication

ring         - Agents in circular communication pattern
             - Best for: Pipeline processing, sequential tasks

star         - Central hub with spoke agents
             - Best for: Centralized coordination, distributed execution
```

---

## STRATEGY SELECTION GUIDE

```
parallel     - Execute all tasks concurrently
             - Best for: Independent tasks, maximum speed

sequential   - Execute tasks in order
             - Best for: Dependent tasks, strict ordering

adaptive     - Dynamically adjust strategy based on task analysis
             - Best for: Complex tasks, unknown dependencies

balanced     - Hybrid approach optimizing for throughput
             - Best for: Mixed workloads, resource optimization
```

---

## ERROR HANDLING

### Memory System Errors

```
IF memory_usage fails:
  1. CHECK namespace exists
  2. TRY memory_namespace("create")
  3. RETRY memory_usage
  4. FALLBACK to different namespace
```

### Swarm Initialization Errors

```
IF swarm_init fails:
  1. CHECK existing swarms with swarm_status()
  2. DESTROY stale swarms with swarm_destroy()
  3. RETRY swarm_init
```

### Agent Spawn Errors

```
IF agent_spawn fails:
  1. CHECK swarm_status for capacity
  2. TRY swarm_scale to increase capacity
  3. RETRY agent_spawn
  4. FALLBACK to agents_spawn_parallel with lower concurrency
```

---

## PERFORMANCE OPTIMIZATION

### Token Efficiency

```
USE memory_search instead of memory_usage("list") - More targeted
USE agents_spawn_parallel for multiple agents - 10-20x faster
USE adaptive strategy for unknown workloads - Auto-optimizes
USE namespace filtering - Reduces search space
```

### Concurrency Optimization

```
parallel_execute for independent tasks
batch_process for bulk operations
agents_spawn_parallel with optimal batchSize (default: 3)
swarm_scale dynamically based on load
```

---

## SUBPROCESS FALLBACK

ONLY if MCP tools unavailable:

```bash
npx claude-flow@alpha init --force
npx claude-flow@alpha status
npx claude-flow@alpha memory store <key> "<value>" --namespace <ns> --reasoningbank
npx claude-flow@alpha memory query "<search>" --namespace <ns> --reasoningbank
npx claude-flow@alpha swarm "<task>" --strategy <type>
npx claude-flow@alpha hive-mind spawn "<objective>"
```

---

## INTEGRATION WITH OTHER MCP TOOLS

### With Context7

```
1. mcp__context7__resolve-library-id({ libraryName: "library" })
2. mcp__context7__get-library-docs({ context7CompatibleLibraryID: "id" })
3. mcp__claude-flow__memory_usage({ action: "store", namespace: "research" })
```

### With Googler

```
1. mcp__googler__research_topic({ query: "topic", num_results: 3 })
2. mcp__claude-flow__agent_spawn({ type: "analyst" })
3. mcp__claude-flow__task_orchestrate({ task: "synthesize findings" })
4. mcp__claude-flow__memory_usage({ action: "store", namespace: "research" })
```

---

**STATUS:** Native MCP tools verified and connected
**MODE:** Direct tool invocation (no subprocess)
**OPTIMIZED FOR:** LLM execution efficiency

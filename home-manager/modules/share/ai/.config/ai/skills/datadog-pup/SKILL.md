---
name: datadog-pup
description: Use when interacting with Datadog resources using the `pup` CLI, especially for APM traces, metrics, monitors, notebooks, and synthetic tests.
---

# pup CLI — Datadog Resource Management

## Overview

`pup` is a Datadog API CLI. Use it to query APM traces, metrics, monitors, logs, synthetics, SLOs, dashboards, and more.

## Global Flags

- `-o json|table|yaml` — output format (default: `json`)
- `-y` — auto-approve destructive ops
- `--agent` — enable agent mode (structured output for AI)
- `--org <name>` — named org session for multi-org support (see `pup auth login --org`)

**Prefer `--agent` flag** when parsing output programmatically — it normalizes output for machine consumption.

## Multi-Org / Auth

If credentials fail or results look wrong (e.g. only `phone-assistant` services visible), check which org is active:

```bash
pup auth status          # show active org/session
pup auth login --org monolith   # authenticate against the monolith org
pup test                 # verify credentials work
```

Use `--org monolith` on any command to scope it to the right org.

## APM — Traces & Services

> ⚠️ APM durations are in **NANOSECONDS**: 1s = 1,000,000,000 ns, 5ms = 5,000,000 ns

### Traces (spans)

```bash
# Search for recent slow spans on a resource
pup traces search --query 'service:monolith resource_name:"MyController#action"' --from 1h

# Filter errors
pup traces search --query 'service:monolith status:error' --from 30m --limit 20

# Aggregate: count by resource_name
pup traces aggregate --query 'service:monolith' --compute count --group-by resource_name --from 1h

# Aggregate: p99 latency per endpoint
pup traces aggregate \
  --query 'service:monolith env:production' \
  --compute 'percentile(@duration, 99)' \
  --group-by resource_name \
  --from 1h

# Average duration for a specific endpoint
pup traces aggregate \
  --query 'resource_name:"AnonymousFunnel::AnonymousResource::AttachMedicalDataController#create"' \
  --compute 'avg(@duration)' \
  --from 1h
```

### APM Services

```bash
# List all services in an environment
pup apm services list --env production --from 1h

# Service performance stats (throughput, latency, error rate)
pup apm services stats --env production --from 1h

# List operations for a service
pup apm services operations --env production --service monolith

# List resources (endpoints) for a specific operation
pup apm services resources --env production --service monolith --operation rack.request

# Service dependency map
pup apm dependencies list --env production
```

## Metrics

```bash
# Query a metric time series
pup metrics query --query 'avg:trace.rack.request.duration{service:monolith}' --from 1h

# Find available metrics by name pattern
pup metrics list --filter 'trace.*' --tag-filter 'service:monolith'

# Search metrics
pup metrics search --query 'trace.rack.request'
```

## Team Context

You are on the `p3c` team. **Always filter by team before listing resources** — Datadog has too many shared resources to browse unfiltered.

## Quick Reference

### Monitors

```bash
# Always filter by team tag to avoid drowning in unrelated monitors
pup monitors list --tags "team:p3c"
pup monitors list --tags "team:p3c" --name "payment"  # further narrow by name
pup monitors search --query "tag:team:p3c status:alert"
pup monitors get <MONITOR_ID>
pup monitors create --file monitor.json
pup monitors update <MONITOR_ID> --file monitor.json
pup monitors delete <MONITOR_ID>
```

### Logs

```bash
# Scope logs to your service or team to avoid noise
pup logs list --query "team:p3c service:api status:error"
pup logs search --query "team:p3c @http.status:500"
pup logs aggregate  # group/count logs
```

### Synthetics

```bash
# No tag filter available — use --text to search by name prefix
pup synthetics tests list
pup synthetics tests search --text "p3c"
pup synthetics tests get <TEST_ID>
```

### Notebooks

```bash
pup notebooks list
pup notebooks get <NOTEBOOK_ID>
pup notebooks create --file notebook.json
pup notebooks update <NOTEBOOK_ID> --file notebook.json
pup notebooks delete <NOTEBOOK_ID>
```

### SLOs

```bash
pup slos list
pup slos get <SLO_ID>
pup slos status <SLO_ID>
pup slos create --file slo.json
pup slos update <SLO_ID> --file slo.json
```

### Other Useful Commands

```bash
pup dashboards list
pup incidents list
pup events list
pup downtime list
pup users list
pup test  # verify credentials
```

## Workflows

### Find then act

Always `list` or `search` before mutating — capture the ID first:

```bash
# Find the monitor
pup monitors list --name "checkout latency" -o table

# Then act on it
pup monitors get 123456
pup monitors update 123456 --file updated.json
```

### Create/update from file

`create` and `update` take a `--file` with a JSON payload. Get the schema from an existing resource:

```bash
# Export existing as template
pup monitors get 123456 -o json > monitor.json

# Edit monitor.json, then create new
pup monitors create --file monitor.json
```

### Destructive operations

Use `-y` to skip confirmation prompts in automation:

```bash
pup monitors delete 123456 -y
```

## Common Mistakes

- Listing without a team filter → always scope with `--tags "team:p3c"` or `--query "tag:team:p3c"` first
- Parsing default output in scripts → use `--agent` for cleaner structured output
- Running `delete` without checking first → always `get` before `delete`
- Creating from scratch → export existing with `get -o json`, edit, then `create`
- Wrong `--tags` syntax → must be comma-separated: `team:p3c,env:prod`

## Discovery

```bash
pup -h                     # top-level commands
pup <command> -h           # subcommands
pup <command> <sub> -h     # flags for specific operation
pup agent guide            # operational reference for the datadog-agent daemon
pup agent schema           # full JSON schema of all commands
```

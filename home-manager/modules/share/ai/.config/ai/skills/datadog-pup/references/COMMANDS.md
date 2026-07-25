# `pup` command patterns

## Global flags

- `-o json|table|yaml` picks the output format. Default is `json`.
- `--agent` normalizes output for machine use.
- `--org <name>` picks the Datadog org.
- `-y` skips confirmation for destructive commands.

## Auth and scope

```bash
pup auth status
pup auth login --org monolith
pup test
```

Use `--org monolith` when the active org is wrong.

## Traces and APM

```bash
# recent slow spans on one resource
pup traces search --query 'service:monolith resource_name:"MyController#action"' --from 1h

# recent errors
pup traces search --query 'service:monolith status:error' --from 30m --limit 20

# count by resource
pup traces aggregate --query 'service:monolith' --compute count --group-by resource_name --from 1h

# p99 latency by endpoint
pup traces aggregate \
  --query 'service:monolith env:production' \
  --compute 'percentile(@duration, 99)' \
  --group-by resource_name \
  --from 1h

# average duration for one endpoint
pup traces aggregate \
  --query 'resource_name:"AnonymousFunnel::AnonymousResource::AttachMedicalDataController#create"' \
  --compute 'avg(@duration)' \
  --from 1h

# list services, operations, resources, and dependencies
pup apm services list --env production --from 1h
pup apm services stats --env production --from 1h
pup apm services operations --env production --service monolith
pup apm services resources --env production --service monolith --operation rack.request
pup apm dependencies list --env production
```

## Metrics

```bash
pup metrics query --query 'avg:trace.rack.request.duration{service:monolith}' --from 1h
pup metrics list --filter 'trace.*' --tag-filter 'service:monolith'
pup metrics search --query 'trace.rack.request'
```

## Monitors

Always scope shared monitors first.

```bash
pup monitors list --tags 'team:p3c'
pup monitors list --tags 'team:p3c' --name 'payment'
pup monitors search --query 'tag:team:p3c status:alert'
pup monitors get <MONITOR_ID>
pup monitors create --file monitor.json
pup monitors update <MONITOR_ID> --file monitor.json
pup monitors delete <MONITOR_ID>
```

## Logs

```bash
pup logs list --query 'team:p3c service:api status:error'
pup logs search --query 'team:p3c @http.status:500'
pup logs aggregate
```

## Synthetics

```bash
pup synthetics tests list
pup synthetics tests search --text 'p3c'
pup synthetics tests get <TEST_ID>
```

## Notebooks

```bash
pup notebooks list
pup notebooks get <NOTEBOOK_ID>
pup notebooks create --file notebook.json
pup notebooks update <NOTEBOOK_ID> --file notebook.json
pup notebooks delete <NOTEBOOK_ID>
```

## SLOs

```bash
pup slos list
pup slos get <SLO_ID>
pup slos status <SLO_ID>
pup slos create --file slo.json
pup slos update <SLO_ID> --file slo.json
```

## Other useful commands

```bash
pup dashboards list
pup incidents list
pup events list
pup downtime list
pup users list
pup test
```

## Safe change pattern

```bash
# find the target first
pup monitors list --name 'checkout latency' -o table

# inspect it
pup monitors get 123456

# export it as a template
pup monitors get 123456 -o json > monitor.json

# edit the file, then apply it
pup monitors update 123456 --file monitor.json
```

## Discovery

```bash
pup -h
pup <command> -h
pup <command> <subcommand> -h
pup agent guide
pup agent schema
```

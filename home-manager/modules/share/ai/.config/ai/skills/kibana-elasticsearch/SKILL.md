---
name: kibana-elasticsearch
description: Use when querying an Elasticsearch index via the Kibana console proxy, filtering logs by field values, or investigating errors from job or application logs.
---

# Kibana / Elasticsearch Querying

## Overview

Elasticsearch logs are queryable via `curl` through the Kibana console proxy. No MCP server needed.

## Prerequisites

Check that the required env vars are set. Never echo or print their values.

```bash
[ -n "$ES_API_KEY" ] && echo "ES_API_KEY: set" || echo "ES_API_KEY: NOT SET"
[ -n "$KIBANA_URL" ] && echo "KIBANA_URL: set" || echo "KIBANA_URL: NOT SET"
```

If the instance is behind Cloudflare Access, also verify cloudflared is authenticated:

```bash
command -v cloudflared &>/dev/null && echo "cloudflared: available" || echo "cloudflared: not found"
```

Stop and ask the user to configure missing variables before proceeding.

## Query Template

```bash
# Omit the CF_TOKEN line if not behind Cloudflare Access
CF_TOKEN=$(cloudflared access token -app="$KIBANA_URL" 2>/dev/null)

curl -s \
  ${CF_TOKEN:+-H "cf-access-token: $CF_TOKEN"} \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey $ES_API_KEY" \
  "$KIBANA_URL/api/console/proxy?path=<index>%2F_search&method=POST" \
  -d '{ <ES query body> }' | python3 -m json.tool
```

URL-encode the path: `/` becomes `%2F`. Use a wildcard index pattern like `logs*` or `jobs*` to cover multiple indices.

## Discover Fields

Run this before writing queries on an unfamiliar index.

```bash
curl -s \
  ${CF_TOKEN:+-H "cf-access-token: $CF_TOKEN"} \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey $ES_API_KEY" \
  "$KIBANA_URL/api/console/proxy?path=<index>%2F_mapping&method=GET" | python3 -m json.tool
```

## Common Queries

### All documents in a time range (chronological)

```json
{
  "size": 200,
  "sort": [{"@timestamp": {"order": "asc"}}],
  "_source": ["@timestamp", "message", "level"],
  "query": {
    "bool": {
      "must": [
        {"range": {"@timestamp": {"gte": "2026-06-01T08:00:00Z", "lte": "2026-06-01T12:00:00Z"}}}
      ]
    }
  }
}
```

### Filter by field value and time window

```json
{
  "size": 50,
  "sort": [{"@timestamp": {"order": "asc"}}],
  "query": {
    "bool": {
      "must": [
        {"term": {"some.field": "some-value"}},
        {"range": {"@timestamp": {"gte": "now-2d", "lte": "now"}}}
      ]
    }
  }
}
```

### Errors only (match any of several conditions)

```json
{
  "size": 50,
  "sort": [{"@timestamp": {"order": "asc"}}],
  "query": {
    "bool": {
      "must": [
        {"range": {"@timestamp": {"gte": "now-2d", "lte": "now"}}}
      ],
      "should": [
        {"term": {"level": "ERROR"}},
        {"exists": {"field": "exception.class"}}
      ],
      "minimum_should_match": 1
    }
  }
}
```

### Full-text search in a field

```json
{
  "size": 20,
  "sort": [{"@timestamp": {"order": "desc"}}],
  "query": {
    "bool": {
      "must": [
        {"match": {"message": "some error phrase"}},
        {"range": {"@timestamp": {"gte": "now-7d", "lte": "now"}}}
      ]
    }
  }
}
```

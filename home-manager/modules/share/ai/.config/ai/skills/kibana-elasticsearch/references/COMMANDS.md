# Kibana console proxy commands

Use these patterns when the skill needs exact commands.

## Check access

Never print secret values.

```bash
[ -n "$ES_API_KEY" ] && echo "ES_API_KEY: set" || echo "ES_API_KEY: NOT SET"
[ -n "$KIBANA_URL" ] && echo "KIBANA_URL: set" || echo "KIBANA_URL: NOT SET"
command -v cloudflared >/dev/null && echo "cloudflared: available" || echo "cloudflared: not found"
```

If required values are missing, stop and ask the user to configure them.

## Build the proxy request

Omit the `CF_TOKEN` line when Cloudflare Access does not apply.

```bash
CF_TOKEN=$(cloudflared access token -app="$KIBANA_URL" 2>/dev/null)

curl -s \
  ${CF_TOKEN:+-H "cf-access-token: $CF_TOKEN"} \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey $ES_API_KEY" \
  "$KIBANA_URL/api/console/proxy?path=<index>%2F_search&method=POST" \
  -d '{ <ES query body> }' | python3 -m json.tool
```

Use wildcard patterns like `logs*` or `jobs*` when the data may span multiple indices.

## Discover mappings first

```bash
curl -s \
  ${CF_TOKEN:+-H "cf-access-token: $CF_TOKEN"} \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey $ES_API_KEY" \
  "$KIBANA_URL/api/console/proxy?path=<index>%2F_mapping&method=GET" | python3 -m json.tool
```

Check the mapping before you choose field names or query operators.

## Query patterns

### All documents in a time range

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

### Errors only

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

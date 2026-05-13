#!/usr/bin/env bash
# monitor-canary.sh — polls Datadog during canary rollout
# Fails if error rate or p99 latency exceed thresholds.

set -euo pipefail

API_KEY="${DATADOG_API_KEY:?DATADOG_API_KEY is required}"
APP_KEY="${DATADOG_APP_KEY:-}"
ERROR_THRESHOLD="${ERROR_RATE_THRESHOLD:-1.0}"   # percent
LATENCY_THRESHOLD="${LATENCY_P99_THRESHOLD:-2000}" # ms
POLL_INTERVAL=30                                  # seconds
MONITOR_DURATION=300                              # 5 minutes total

log() { echo "[$(date -u +%H:%M:%S)] $*"; }
fail() { echo "❌ $*" >&2; exit 1; }

query_datadog() {
  local metric="$1"
  local query="$2"
  local now
  now=$(date +%s)
  local from=$((now - 120))  # last 2 minutes

  curl -sf \
    -H "DD-API-KEY: $API_KEY" \
    -H "DD-APPLICATION-KEY: $APP_KEY" \
    "https://api.datadoghq.com/api/v1/query?from=$from&to=$now&query=$query" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
series = data.get('series', [])
if not series or not series[0].get('pointlist'):
    print('0')
else:
    pts = [p[1] for p in series[0]['pointlist'] if p[1] is not None]
    print(f'{max(pts):.2f}' if pts else '0')
"
}

log "Monitoring canary for ${MONITOR_DURATION}s (polling every ${POLL_INTERVAL}s)"
log "Error threshold: ${ERROR_THRESHOLD}% | P99 latency threshold: ${LATENCY_THRESHOLD}ms"

elapsed=0
while [[ $elapsed -lt $MONITOR_DURATION ]]; do
  error_rate=$(query_datadog "error_rate" \
    "sum:trace.web.request.errors{service:saas-app,env:production,version:canary}.as_rate() / sum:trace.web.request.hits{service:saas-app,env:production,version:canary}.as_rate() * 100")

  p99_latency=$(query_datadog "p99_latency" \
    "p99:trace.web.request.duration{service:saas-app,env:production,version:canary}")

  log "Error rate: ${error_rate}% | P99 latency: ${p99_latency}ms | Elapsed: ${elapsed}s"

  if (( $(echo "$error_rate > $ERROR_THRESHOLD" | bc -l) )); then
    fail "Error rate ${error_rate}% exceeded threshold ${ERROR_THRESHOLD}% — aborting canary"
  fi

  if (( $(echo "$p99_latency > $LATENCY_THRESHOLD" | bc -l) )); then
    fail "P99 latency ${p99_latency}ms exceeded threshold ${LATENCY_THRESHOLD}ms — aborting canary"
  fi

  sleep "$POLL_INTERVAL"
  elapsed=$((elapsed + POLL_INTERVAL))
done

log "Canary passed all checks ✅ — promoting to full rollout"
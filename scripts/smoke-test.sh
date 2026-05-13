#!/usr/bin/env bash
# smoke-test.sh — runs after every deployment to verify basic health
# Usage: ./scripts/smoke-test.sh https://staging.yoursaas.com

set -euo pipefail

BASE_URL="${1:-http://localhost:3000}"
TOKEN="${SMOKE_TEST_TOKEN:-}"
MAX_RETRIES=5
RETRY_DELAY=5

log() { echo "[$(date -u +%H:%M:%S)] $*"; }
fail() { echo "❌ FAILED: $*" >&2; exit 1; }
pass() { echo "✅ PASSED: $*"; }

# ─────────────────────────────────────────
# Helper: HTTP check with retries
# ─────────────────────────────────────────
check() {
  local label="$1"
  local url="$2"
  local expected_status="${3:-200}"
  local extra_args=("${@:4}")

  for i in $(seq 1 "$MAX_RETRIES"); do
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      "${extra_args[@]}" \
      --max-time 10 "$url")

    if [[ "$status" == "$expected_status" ]]; then
      pass "$label (HTTP $status)"
      return 0
    fi

    log "Attempt $i/$MAX_RETRIES — $label returned HTTP $status, expected $expected_status"
    sleep "$RETRY_DELAY"
  done

  fail "$label — got HTTP $status after $MAX_RETRIES attempts"
}

log "Starting smoke tests against $BASE_URL"

# Health & readiness
check "Health endpoint"     "$BASE_URL/health"          200
check "Readiness endpoint"  "$BASE_URL/ready"           200
check "Metrics endpoint"    "$BASE_URL/metrics"         200

# Public API endpoints
check "API root"            "$BASE_URL/api/v1"          200
check "Auth endpoint"       "$BASE_URL/api/v1/auth"     401   # no token = 401

# Authenticated endpoints
check "User profile"        "$BASE_URL/api/v1/me"       200
check "Workspace list"      "$BASE_URL/api/v1/workspaces" 200

# Static assets
check "Front-end served"    "$BASE_URL/"                200
check "favicon.ico"         "$BASE_URL/favicon.ico"     200

# Verify response body contains expected marker
body=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/v1")
if echo "$body" | grep -q '"status":"ok"'; then
  pass "API response body contains status:ok"
else
  fail "API response body missing status:ok — got: $body"
fi

log "All smoke tests passed ✅"
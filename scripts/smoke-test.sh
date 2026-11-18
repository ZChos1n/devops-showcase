#!/usr/bin/env bash
# Smoke test: verify the deployed app answers on key endpoints.
set -euo pipefail

NS="${NS:-showcase-dev}"
SVC="${SVC:-showcase-api}"
LOCAL_PORT="${LOCAL_PORT:-8080}"

echo "==> Port-forwarding svc/$SVC in ns/$NS ..."
kubectl -n "$NS" port-forward "svc/$SVC" "${LOCAL_PORT}:80" >/tmp/pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
sleep 4

echo "==> Checking /healthz"
curl --fail --retry 5 --retry-delay 2 "http://localhost:${LOCAL_PORT}/healthz"

echo
echo "==> Checking /metrics contains our custom counter"
curl -s "http://localhost:${LOCAL_PORT}/metrics" | grep -q "http_requests_total" && echo "metrics OK"

echo "==> Smoke test PASSED"

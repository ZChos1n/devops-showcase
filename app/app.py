"""A small-but-realistic service used to demonstrate a full DevOps workflow.

Endpoints:
    GET /            -> service info
    GET /healthz     -> liveness probe  (is the process alive?)
    GET /readyz      -> readiness probe (can it serve traffic?)
    GET /metrics     -> Prometheus metrics
    GET /api/items   -> demo data endpoint (supports failure injection)

The failure injection on /api/items?fail=1 exists purely so the repository can
demonstrate alerting and incident postmortems without a real outage.
"""

from __future__ import annotations

import os
import random
import time

from fastapi import FastAPI, HTTPException, Request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)
from starlette.responses import Response

SERVICE_NAME = os.getenv("SERVICE_NAME", "showcase-api")
SERVICE_VERSION = os.getenv("SERVICE_VERSION", "dev")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
FAILURE_RATE = float(os.getenv("FAILURE_RATE", "0"))

# ---- Prometheus metrics ---------------------------------------------------
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5),
)
IN_FLIGHT = Gauge("http_requests_in_flight", "Requests currently in flight")
APP_INFO = Gauge("app_info", "Build information", ["version", "environment"])
APP_INFO.labels(version=SERVICE_VERSION, environment=ENVIRONMENT).set(1)

app = FastAPI(title=SERVICE_NAME, version=SERVICE_VERSION)


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Record latency, count and in-flight gauge for every request, including /metrics."""
    start = time.perf_counter()
    IN_FLIGHT.inc()
    try:
        response = await call_next(request)
        status = response.status_code
    except Exception:
        status = 500
        raise
    finally:
        IN_FLIGHT.dec()
        elapsed = time.perf_counter() - start
        endpoint = request.url.path
        REQUEST_LATENCY.labels(method=request.method, endpoint=endpoint).observe(elapsed)
        REQUEST_COUNT.labels(
            method=request.method, endpoint=endpoint, http_status=str(status)
        ).inc()
    return response


@app.get("/")
def root():
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": ENVIRONMENT,
    }


@app.get("/healthz")
def healthz():
    """Liveness: deliberately shallow. A deep check here can cause restart storms."""
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    """Readiness: in a real app this would check DB/cache dependencies."""
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/items")
def list_items(fail: int = 0):
    """Demo endpoint with optional failure injection for alert drills."""
    if fail == 1 or (FAILURE_RATE > 0 and random.random() < FAILURE_RATE):
        raise HTTPException(status_code=503, detail="injected upstream failure")
    # Simulate variable latency so the histogram has meaningful data.
    time.sleep(random.uniform(0.005, 0.08))
    return {"items": ["alpha", "beta", "gamma"], "count": 3}

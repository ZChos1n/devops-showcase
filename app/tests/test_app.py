"""Unit tests. Kept dependency-light so CI can run them in seconds.

Import is resolved by absolute path so the suite works both from the repo root
(`pytest app/tests`, as the Makefile does) and from `app/` (`pytest -q`, as CI
does). Without this, `app` is ambiguous: it is both a directory and a module.
"""

import os
import sys

os.environ.setdefault("ENVIRONMENT", "test")

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if APP_DIR not in sys.path:
    sys.path.insert(0, APP_DIR)

from fastapi.testclient import TestClient  # noqa: E402

from app import app as fastapi_app  # noqa: E402

client = TestClient(fastapi_app)


def test_root_returns_service_info():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["environment"] == "test"


def test_healthz_and_readyz():
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").json() == {"status": "ready"}


def test_metrics_exposes_custom_counter():
    client.get("/api/items")
    body = client.get("/metrics").text
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body


def test_failure_injection_returns_503():
    r = client.get("/api/items", params={"fail": 1})
    assert r.status_code == 503

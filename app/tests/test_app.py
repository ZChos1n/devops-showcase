"""Unit tests. Kept dependency-light so CI can run them in seconds."""

import os

os.environ.setdefault("ENVIRONMENT", "test")

from fastapi.testclient import TestClient  # noqa: E402

from app import app  # noqa: E402

client = TestClient(app)


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

#!/usr/bin/env python3
"""
health_check.py

Polls the /healthz endpoint of the service on both AWS and GCP clusters,
records latency and status, and writes results to a JSON log for
Prometheus's node-exporter textfile collector to pick up.

Usage:
    python health_check.py --config endpoints.json --out /var/lib/node_exporter/textfile_collector/health.prom
"""

import argparse
import json
import time
import urllib.request
import urllib.error


def check_endpoint(name: str, url: str, timeout: float = 5.0) -> dict:
    start = time.time()
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            elapsed = time.time() - start
            return {
                "name": name,
                "url": url,
                "status_code": resp.getcode(),
                "healthy": resp.getcode() == 200,
                "latency_seconds": round(elapsed, 4),
            }
    except (urllib.error.URLError, TimeoutError) as exc:
        elapsed = time.time() - start
        return {
            "name": name,
            "url": url,
            "status_code": None,
            "healthy": False,
            "latency_seconds": round(elapsed, 4),
            "error": str(exc),
        }


def write_prometheus_textfile(results: list, out_path: str) -> None:
    lines = [
        "# HELP service_healthy Whether the service health check passed (1) or failed (0)",
        "# TYPE service_healthy gauge",
    ]
    for r in results:
        lines.append(f'service_healthy{{cloud="{r["name"]}"}} {1 if r["healthy"] else 0}')
        lines.append(f'service_health_latency_seconds{{cloud="{r["name"]}"}} {r["latency_seconds"]}')

    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Cross-cloud health check")
    parser.add_argument("--config", default="endpoints.json", help="JSON file mapping cloud name -> health URL")
    parser.add_argument("--out", default="health.prom", help="Prometheus textfile output path")
    args = parser.parse_args()

    with open(args.config) as f:
        endpoints = json.load(f)

    results = [check_endpoint(name, url) for name, url in endpoints.items()]

    for r in results:
        status = "OK" if r["healthy"] else "FAIL"
        print(f'[{status}] {r["name"]:<6} {r["url"]}  ({r["latency_seconds"]}s)')

    write_prometheus_textfile(results, args.out)

    if any(not r["healthy"] for r in results):
        raise SystemExit(1)


if __name__ == "__main__":
    main()

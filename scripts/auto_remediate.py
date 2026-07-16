#!/usr/bin/env python3
"""
auto_remediate.py

Simple remediation loop: if health_check.py reports a cloud as unhealthy,
restart the affected deployment's pods on that cloud's kubectl context.
Intended to be run from a scheduled CI job or a lightweight cron/systemd timer,
not as a replacement for a full incident-response process.

Usage:
    python auto_remediate.py --health health.json --deployment app --namespace default
"""

import argparse
import json
import subprocess
import sys

CONTEXT_MAP = {
    "aws": "aws-eks",
    "gcp": "gcp-gke",
}


def restart_deployment(context: str, deployment: str, namespace: str) -> bool:
    cmd = [
        "kubectl", "--context", context,
        "rollout", "restart", f"deployment/{deployment}",
        "-n", namespace,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Restarted {deployment} in {namespace} on context {context}")
        return True
    print(f"Failed to restart on {context}: {result.stderr}", file=sys.stderr)
    return False


def main():
    parser = argparse.ArgumentParser(description="Auto-remediate unhealthy cloud deployments")
    parser.add_argument("--health", required=True, help="JSON list of health_check.py results")
    parser.add_argument("--deployment", default="app")
    parser.add_argument("--namespace", default="default")
    args = parser.parse_args()

    with open(args.health) as f:
        results = json.load(f)

    unhealthy = [r["name"] for r in results if not r.get("healthy", True)]

    if not unhealthy:
        print("All clouds healthy, no action taken.")
        return

    for cloud in unhealthy:
        context = CONTEXT_MAP.get(cloud)
        if not context:
            print(f"No kubectl context mapped for cloud '{cloud}', skipping.")
            continue
        restart_deployment(context, args.deployment, args.namespace)


if __name__ == "__main__":
    main()

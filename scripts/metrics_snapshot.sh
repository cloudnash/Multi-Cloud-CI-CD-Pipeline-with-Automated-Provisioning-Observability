#!/usr/bin/env bash
#
# metrics_snapshot.sh
# Captures CPU, memory, disk, and Kubernetes pod status for both the AWS
# and GCP kubectl contexts into a single timestamped snapshot folder.
# Useful as evidence before logs rotate, or for quick incident triage.
#
# Usage: ./metrics_snapshot.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-./snapshots}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_DIR"

echo "Writing snapshot to $OUT_DIR"

# ---- System-level metrics (run on whichever node this executes on) ----
{
  echo "== CPU =="
  top -bn1 | head -15
  echo
  echo "== Memory =="
  free -h
  echo
  echo "== Disk =="
  df -h
} > "$OUT_DIR/system_metrics.txt"

# ---- Kubernetes pod status, per cloud context ----
for CTX in aws-eks gcp-gke; do
  if kubectl config get-contexts "$CTX" >/dev/null 2>&1; then
    echo "Capturing pod status for context: $CTX"
    kubectl --context "$CTX" get pods -A -o wide > "$OUT_DIR/pods_${CTX}.txt" 2>&1 || true
    kubectl --context "$CTX" get events -A --sort-by='.lastTimestamp' > "$OUT_DIR/events_${CTX}.txt" 2>&1 || true
  else
    echo "Context $CTX not found, skipping" >> "$OUT_DIR/warnings.txt"
  fi
done

# ---- Docker container status, if present ----
if command -v docker >/dev/null 2>&1; then
  docker ps -a > "$OUT_DIR/docker_containers.txt" 2>&1 || true
fi

# ---- Recent syslog tail ----
if [ -r /var/log/syslog ]; then
  tail -n 500 /var/log/syslog > "$OUT_DIR/syslog_tail.txt"
fi

echo "Snapshot complete: $OUT_DIR"

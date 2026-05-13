#!/usr/bin/env bash
# prune-old-snapshots.sh — deletes RDS snapshots older than RETENTION_DAYS
# Called by the scheduled workflow

set -euo pipefail

RETENTION_DAYS="${RETENTION_DAYS:-30}"
RDS_INSTANCE_ID="${RDS_INSTANCE_ID:?RDS_INSTANCE_ID is required}"
CUTOFF=$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
         date -v-"${RETENTION_DAYS}"d +%Y-%m-%dT%H:%M:%S)  # macOS fallback

echo "Pruning snapshots for $RDS_INSTANCE_ID older than $RETENTION_DAYS days (before $CUTOFF)..."

snapshots=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$RDS_INSTANCE_ID" \
  --snapshot-type manual \
  --query "DBSnapshots[?SnapshotCreateTime<'$CUTOFF'].DBSnapshotIdentifier" \
  --output text)

if [[ -z "$snapshots" ]]; then
  echo "No snapshots to prune."
  exit 0
fi

for snapshot in $snapshots; do
  echo "Deleting snapshot: $snapshot"
  aws rds delete-db-snapshot --db-snapshot-identifier "$snapshot"
done

echo "Done. Pruned $(echo "$snapshots" | wc -w | tr -d ' ') snapshot(s)."
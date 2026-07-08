#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker compose up -d hdfs-namenode hdfs-datanode-1 hdfs-datanode-2 hdfs-datanode-3 spark-master spark-worker-1 spark-worker-2

echo "Attente du demarrage Spark..."
sleep 20

docker compose --profile tools run --rm spark-job

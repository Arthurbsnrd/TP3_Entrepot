#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

python generate_data.py

docker compose up -d hdfs-namenode hdfs-datanode-1 hdfs-datanode-2 hdfs-datanode-3

echo "Attente du demarrage HDFS..."
sleep 15

docker compose --profile tools run --rm hdfs-init

echo "Chargement termine."

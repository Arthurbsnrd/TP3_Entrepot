#!/bin/bash
set -euo pipefail

echo "Attente du master Spark..."
for _ in $(seq 1 60); do
  if getent hosts spark-master > /dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Lancement du job Spark..."
/spark/bin/spark-submit --master spark://spark-master:7077 /workspace/spark_job.py

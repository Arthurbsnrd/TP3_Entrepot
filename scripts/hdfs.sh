#!/bin/bash
set -euo pipefail

docker compose exec -T hdfs-namenode /entrypoint.sh /opt/hadoop-3.2.1/bin/hdfs "$@"

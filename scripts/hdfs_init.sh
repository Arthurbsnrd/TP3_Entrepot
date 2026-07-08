#!/bin/bash
set -euo pipefail

HDFS=/opt/hadoop-3.2.1/bin/hdfs

echo "Attente du cluster HDFS..."
until "$HDFS" dfs -ls / > /dev/null 2>&1; do
  sleep 3
done

echo "Creation du repertoire /user/commandes"
"$HDFS" dfs -mkdir -p /user/commandes

echo "Chargement des CSV dans HDFS"
"$HDFS" dfs -put -f /data/commandes_*.csv /user/commandes

echo "Fichiers HDFS listes :"
"$HDFS" dfs -ls /user/commandes

echo "Preuve de replication :"
"$HDFS" fsck /user/commandes -files -blocks -locations

# TP 3 — L'entrepôt résilient (HDFS & Spark)

Ce projet met en place un cluster HDFS distribué avec un facteur de réplication de 3, puis un cluster Spark standalone qui lit directement depuis HDFS et écrit des résultats agrégés en Parquet.

## Contenu du dépôt

- `docker-compose.yml` : cluster HDFS + Spark + services utilitaires
- `generate_data.py` : génération des trois fichiers CSV du TP
- `spark_job.py` : job Spark qui lit les CSV depuis HDFS, calcule les agrégations, et écrit le résultat en Parquet dans HDFS
- `scripts/` : scripts de chargement HDFS, exécution Spark et wrapper HDFS
- `data/` : dossier de stockage local des données générées

## Prérequis

- Docker Desktop / Docker Engine
- Docker Compose v2 ou supérieur
- Python 3.x installé sur la machine hôte

## Étapes

### 1. Générer les données CSV sur l'hôte

```bash
python generate_data.py
```

Les fichiers seront écrits dans `data/` :
- `commandes_2026-06-12.csv`
- `commandes_2026-06-13.csv`
- `commandes_2026-06-14.csv`

### 2. Démarrer le cluster HDFS + Spark

```bash
docker compose up -d hdfs-namenode hdfs-datanode-1 hdfs-datanode-2 hdfs-datanode-3 spark-master spark-worker-1 spark-worker-2
```

Attendre ~20 secondes que HDFS et Spark soient prêts.

Interfaces web :
- HDFS NameNode : http://localhost:9870
- Spark Master : http://localhost:8090

### 3. Charger les fichiers dans HDFS

```bash
docker compose --profile tools run --rm hdfs-init
```

Le service `hdfs-init` effectue :
- création du répertoire `/user/commandes`
- chargement des CSV dans HDFS
- vérification des blocs et des emplacements (`hdfs fsck`)

Alternative tout-en-un (génération + démarrage HDFS + chargement) :

```bash
bash scripts/load_data.sh
```

### 4. Vérifier la réplication dans HDFS

Avant arrêt d'un DataNode :

```bash
bash scripts/hdfs.sh fsck /user/commandes -files -blocks -locations
```

Pour un rapport plus large :

```bash
bash scripts/hdfs.sh dfsadmin -report
```

Chaque fichier CSV (~76 Ko) forme un bloc unique, répliqué 3 fois sur les 3 datanodes.

### 5. Lancer le job Spark

```bash
docker compose --profile tools run --rm spark-job
```

Alternative :

```bash
bash scripts/run_spark_job.sh
```

Le job lit les trois fichiers CSV depuis `hdfs://namenode:9000/user/commandes/*.csv`, calcule :
- chiffre d'affaires total par entrepôt et par jour
- nombre de commandes par entrepôt et par jour
- panier moyen par entrepôt et par jour

Il écrit le résultat en Parquet dans :

```
hdfs://namenode:9000/user/output/commandes_agregees
```

### 6. Vérifier le résultat Parquet

```bash
bash scripts/hdfs.sh dfs -ls /user/output/commandes_agregees
```

### 7. Tester la tolérance aux pannes

Après un premier succès du job, arrêter un datanode :

```bash
docker compose stop hdfs-datanode-1
```

Vérifier l'état HDFS :

```bash
bash scripts/hdfs.sh fsck /user/commandes -files -blocks -locations
```

Puis relancer le job Spark :

```bash
docker compose --profile tools run --rm spark-job
```

### 8. Observation attendue

- **Avant l'arrêt** : chaque bloc affiche `Live_repl=3` sur 3 datanodes distincts.
- **Après l'arrêt d'un datanode** : le job Spark **réussit** grâce aux répliques restantes (warnings `Connection refused` possibles sur le nœud arrêté).
- HDFS peut signaler des blocs sous-répliqués, mais les données restent lisibles tant qu'au moins une réplique est accessible.

## Notes

- Les fichiers sources ne sont pas lus depuis un chemin local par Spark : la lecture se fait exclusivement via `hdfs://...`.
- La charge des données se fait depuis le dossier local `data/` uniquement lors de l'étape `hdfs-init`.
- Les commandes HDFS passent par `scripts/hdfs.sh` pour garantir la configuration Hadoop correcte dans le conteneur.

## Dépannage

- **Spark master ne démarre pas** : vérifier les logs avec `docker compose logs spark-master`. La variable `SPARK_LOCAL_IP=spark-master` corrige l'erreur `UnknownHostException`.
- **Port 8080 déjà utilisé** : l'interface Spark Master est exposée sur http://localhost:8090 pour éviter les conflits avec d'autres services.
- **hdfs-init échoue** : attendre que les 3 datanodes soient `healthy`, puis relancer la commande.
- **Réinitialiser le cluster** : `docker compose down -v` puis relancer les étapes.


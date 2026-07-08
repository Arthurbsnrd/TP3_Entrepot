from pyspark.sql import SparkSession
from pyspark.sql.functions import col, countDistinct, round, sum as _sum
from pyspark.sql.types import DateType, DoubleType, IntegerType, StringType, StructField, StructType

schema = StructType(
    [
        StructField("id_commande", StringType(), nullable=False),
        StructField("date", DateType(), nullable=False),
        StructField("client_id", StringType(), nullable=False),
        StructField("produit", StringType(), nullable=False),
        StructField("categorie", StringType(), nullable=False),
        StructField("quantite", IntegerType(), nullable=False),
        StructField("prix_unitaire", DoubleType(), nullable=False),
        StructField("entrepot", StringType(), nullable=False),
    ]
)

if __name__ == "__main__":
    spark = SparkSession.builder.appName("TP3-Entrepot").getOrCreate()

    input_path = "hdfs://namenode:9000/user/commandes/*.csv"
    df = (
        spark.read
        .option("header", True)
        .option("dateFormat", "yyyy-MM-dd")
        .schema(schema)
        .csv(input_path)
    )

    print("=== Schéma des données ===")
    df.printSchema()
    print("=== Aperçu des données ===")
    df.show(5, truncate=False)

    df = df.withColumn("chiffre_affaires", col("quantite") * col("prix_unitaire"))

    result = (
        df.groupBy("entrepot", "date")
        .agg(
            round(_sum("chiffre_affaires"), 2).alias("chiffre_affaires_total"),
            countDistinct("id_commande").alias("nombre_commandes"),
        )
        .withColumn(
            "panier_moyen",
            round(col("chiffre_affaires_total") / col("nombre_commandes"), 2),
        )
        .orderBy("date", "entrepot")
    )

    print("=== Résultats agrégés ===")
    result.show(100, truncate=False)

    output_path = "hdfs://namenode:9000/user/output/commandes_agregees"
    result.write.mode("overwrite").parquet(output_path)

    print(f"Résultat écrit dans HDFS : {output_path}")
    spark.stop()

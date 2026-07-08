param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$HdfsArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    docker compose exec -T hdfs-namenode /entrypoint.sh /opt/hadoop-3.2.1/bin/hdfs @HdfsArgs
} finally {
    Pop-Location
}

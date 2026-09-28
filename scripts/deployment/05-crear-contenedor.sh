#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

source scripts/deployment/env/00-config.sh
source "$ORACLE_PWD_FILE"

echo "=== CREANDO Y ARRANCANDO EL CONTENEDOR DE ORACLE ==="
docker run -d \
--name "$CONT_NAME" \
-p "$PORT_DB":1521 \
-p "$PORT_EM":5500 \
-e ORACLE_PWD="$ORACLE_PWD" \
-v "$VOL_NAME":/opt/oracle/oradata \
container-registry.oracle.com/database/free:latest

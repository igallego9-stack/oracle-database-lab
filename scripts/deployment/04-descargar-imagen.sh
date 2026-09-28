#!/bin/bash
source scripts/deployment/env/00-config.sh
echo "=== VERIFICACIÓN Y HUELLA DE LA IMAGEN ORACLE ==="
docker image inspect container-registry.oracle.com/database/free:latest --format='{{index .RepoDigests 0}}'

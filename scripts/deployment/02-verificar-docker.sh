#!/bin/bash
echo "=== VERIFICACIÓN DE DOCKER DESKTOP / WSL ==="
echo -e "\n--- Estado de Docker ---"
docker info | grep -E "Containers|Server Version|Operating System|CPUs|Total Memory"
echo -e "\n--- Imágenes disponibles ---"
docker images container-registry.oracle.com/database/free

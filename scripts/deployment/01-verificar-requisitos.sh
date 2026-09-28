#!/bin/bash
echo "=== VERIFICACIÓN DE REQUISITOS DEL SISTEMA ==="
echo -e "\n--- RAM Disponible ---"
free -h
echo -e "\n--- Procesadores ---"
nproc
echo -e "\n--- Espacio en Disco ---"
df -h /

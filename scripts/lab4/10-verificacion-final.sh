#!/usr/bin/env bash
# scripts/lab4/10-verificacion-final.sh — comprobación automática del estado final del Lab 4
# Cada línea es OK o FALLO. Un FALLO dice qué parte del laboratorio repasar. Entrega solo con todo en OK.
set -uo pipefail
source scripts/deployment/env/00-config.sh
fallos=0
ok()    { printf '  [OK]    %s\n' "$1"; }
fallo() { printf '  [FALLO] %s  -> repasa %s\n' "$1" "$2"; fallos=$((fallos + 1)); }
comprobar() { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else fallo "$1: hay '$2', se esperaba '$3'" "$4"; fi; }

# Una sola consulta como SYSDBA devuelve clave=valor; el resto del script solo compara
VALORES=$(docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 200
SELECT 'open_mode=' || open_mode FROM v$database;
SELECT 'pdb=' || open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
SELECT 'open_cursors=' || value FROM v$parameter WHERE name = 'open_cursors';
SELECT 'db_files_spfile=' || isspecified FROM v$spparameter WHERE name = 'db_files';
SELECT 'ops_ro=' || common FROM cdb_users WHERE username = 'C##OPS_RO' AND con_id = 1;
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT 'fuera_de_carpeta=' || COUNT(*) FROM dba_data_files
 WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\' AND file_name NOT LIKE '/opt/oracle/oradata/FREE/FREEPDB1/%';
SELECT 'tbs_negocio=' || COUNT(*) FROM dba_tablespaces WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\';
SELECT 'con_password=' || COUNT(*) FROM dba_users WHERE username LIKE 'ADMIN\_%' ESCAPE '\' AND
authentication_type <> 'NONE';
SELECT 'v002=' || (SELECT COUNT(*) FROM admin_academia.aca_estudiantes) || '/'
       || (SELECT COUNT(*) FROM admin_academia.aca_asignaturas) || '/'
       || (SELECT COUNT(*) FROM admin_academia.aca_matriculas) FROM dual;
EXIT
SQL
)
val() { echo "$VALORES" | sed -n "s/^$1=//p" | tr -d '[:space:]'; }

echo "== Parte B · Respaldo del Lab 3 =="
BK=$(ls -d backups/*_lab3-final 2>/dev/null | tail -1)
if [ -n "$BK" ] && (cd "$BK" && sha256sum -c --quiet SHA256SUMS); then ok "backup $BK íntegro"; else fallo "no hay backup lab3-final íntegro" "Parte B"; fi
echo "== Parte C · Correcciones del Lab 3 =="
comprobar "tablespaces de negocio" "$(val tbs_negocio)" 5 "Parte C"
comprobar "datafiles de negocio fuera de FREE/FREEPDB1" "$(val fuera_de_carpeta)" 0 "Parte C (03-reubicar)"
FUERA=$(docker exec "$CONT_NAME" bash -c 'for f in /opt/oracle/oradata/FREE/FREEPDB1/*.dbf; do r=$(readlink -f "$f"); case "$r" in /opt/oracle/oradata/*) ;; *) echo "$r";; esac; done' | wc -l)
comprobar "archivos cuya ruta real sale del volumen" "$FUERA" 0 "Parte C (diagnóstico)"
comprobar "cuentas ADMIN_* con contraseña" "$(val con_password)" 0 "Parte C (V003)"
comprobar "datos V002 estudiantes/asignaturas/matrículas" "$(val v002)" "20000/40/60000" "Parte C (V002)"
if docker port "$CONT_NAME" | grep -q '8181'; then fallo "el contenedor sigue publicando 8181" "Parte C (05 v2)"; else ok "8181 ya no se publica"; fi
echo "== Partes D a H · Instancia, parámetros, memoria y procesos =="
comprobar "CDB abierta" "$(val open_mode)" "READWRITE" "Parte E"
comprobar "FREEPDB1 abierta" "$(val pdb)" "READWRITE" "Parte E (SAVE STATE)"
comprobar "C##OPS_RO es común" "$(val ops_ro)" "YES" "Parte D"
comprobar "open_cursors devuelto a su valor" "$(val open_cursors)" 300 "Parte F"
comprobar "db_files sin línea pendiente en el SPFILE" "$(val db_files_spfile)" "FALSE" "Parte F (RESET)"
echo "== Evidencias =="
for n in 00 01 02 03 04 05 06 07 08 09; do
  if ls docs/bitacora/lab4/evidencia/*/*_"$n"-* >/dev/null 2>&1; then ok "evidencia $n"; else fallo "falta la evidencia $n" "la parte correspondiente"; fi
done
if [ -f docs/bitacora/lab4/evidencia/config/initFREE_lab4.ora ]; then ok "PFILE versionado"; else fallo "falta el PFILE" "Parte F"; fi
if git ls-files --error-unmatch config/.env >/dev/null 2>&1; then fallo "config/.env está en Git" ".gitignore"; else ok "config/.env fuera de Git"; fi
if git ls-files | grep -q '^backups/'; then fallo "hay backups versionados en Git" ".gitignore"; else ok "backups/ fuera de Git"; fi
echo
if [ "$fallos" -eq 0 ]; then echo "RESULTADO: TODO OK. Lab 4 listo para entregar."; else echo "RESULTADO: $fallos FALLO(S). Corrige antes de abrir el PR."; fi
exit "$fallos"

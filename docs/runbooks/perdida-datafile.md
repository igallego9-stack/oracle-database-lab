# Pérdida de un datafile de una PDB (TBS_ACADEMIA)

**Síntoma.** Una consulta falla con `ORA-01116` / `ORA-01110` / `ORA-27041`
(`Linux-x86_64 Error: 2: No such file or directory`). En 23ai/26ai puede aparecer
`ORA-63999: data file suffered media failure` y Oracle cierra solo `FREEPDB1`
(la CDB y las demás PDB siguen abiertas).

**No hacer.** No borrar archivos de la FRA con `rm`; no restaurar toda la base si
solo falta un datafile; no abrir con `RESETLOGS`.

## 1. Confirmar el alcance (CDB$ROOT)

```sql
SELECT name, open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
SELECT file#, name, status, online_status FROM v$datafile
 WHERE name LIKE '%academia01.dbf';
SELECT log_mode FROM v$database;          -- debe ser ARCHIVELOG
```

```bash
docker exec oralab-26ai tail -200 \
  /opt/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log \
  | grep -E 'ORA-01116|ORA-01110|ORA-27041|ORA-63999' | tail -5
```

En RMAN, comprobar que hay copia: `LIST BACKUP OF DATAFILE 26;`
(el número y la ruta pueden variar; usar los del diagnóstico).

## 2. Reparar

### Camino A — la PDB sigue en READ WRITE

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE 26 OFFLINE;
```

```text
rman target /
RESTORE DATAFILE 26;
RECOVER DATAFILE 26;
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE 26 ONLINE;
```

### Camino B — Oracle cerró la PDB (ORA-63999), está MOUNTED

No ejecutar `DATAFILE ... OFFLINE`. Esperar a que `v$pdbs.open_mode` sea `MOUNTED`
y, con la PDB montada:

```text
rman target /
RESTORE DATAFILE 26;
RECOVER DATAFILE 26;
```

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE 26 ONLINE;
```

## 3. Verificar y cerrar

```sql
SELECT name, open_mode FROM v$pdbs WHERE name = 'FREEPDB1';  -- READ WRITE
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT estudiante_id, estado FROM admin_academia.aca_estudiantes
 WHERE estudiante_id = 104;                                  -- EGRESADO (si se probó el simulacro)
SELECT COUNT(*) FROM admin_academia.aca_estudiantes;         -- 20000
```

- Confirmar en el alert log que no hay nuevos `ORA-01116`/`ORA-63999`.
- Dejar constancia del RTO (en la prueba: **8 s**) y del RPO (**0**: copia + redo
  archivado + redo online).
- Avisar al responsable de guardia y registrar hora del fallo, archivo, copia usada,
  comandos ejecutados y verificación. Si no hay copia válida o falla `RECOVER`,
  escalar antes de tocar la FRA o restaurar toda la base.

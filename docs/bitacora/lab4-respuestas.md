# Lab 4 — Respuestas

> Respuestas a las **22 preguntas de comprobación** de la Sección 8 y a las **preguntas tipo examen P1–P12**.
> Cada respuesta cita la evidencia del repositorio. La ruta base es
> `docs/bitacora/lab4/evidencia/`; los nombres de archivo y las líneas o valores permiten localizarla.

## 8.1.1 Respaldo

### 1. ¿Por qué la copia de la Parte B es consistente? ¿Qué pasaría si se tomara con la base abierta?

La copia es consistente porque se toma con la base **cerrada de forma limpia**. El script hace
`SHUTDOWN IMMEDIATE` (checkpoint, cierre de archivos y fin de procesos), después `docker stop` y
solo entonces copia el volumen. Al no haber transacciones en vuelo ni escrituras pendientes, los
datafiles, los control files y los redo logs pertenecen al mismo punto de consistencia; al restaurar
no hace falta aplicar redo.

Si se tomara con la base abierta sería una copia **inconsistente** (fuzzy): cada datafile podría
estar en un SCN distinto y parte de los cambios confirmados viviría solo en los redo logs. Para
restaurarla habría que recuperar con redo; en `NOARCHIVELOG` esa recuperación no siempre es posible.
La evidencia muestra el cierre limpio y la copia sin archivos fuera del volumen:
`script/20261024T101824Z_00-backup-lab3.script.log`, líneas 59–65, y el reinicio healthy en las
líneas 67–69.

### 2. ¿Para qué sirven `manifiesto.txt` y `SHA256SUMS`? ¿Qué comprueba `restaurar-estado.sh` antes de tocar nada?

- **`manifiesto.txt`** documenta qué se copió y en qué contexto: fecha UTC, etiqueta, contenedor,
  volumen, imagen, commit de Git, tipo de copia y archivos que quedaron fuera del volumen. Sirve
  para saber qué estado se va a restaurar y para auditar la copia.
- **`SHA256SUMS`** guarda el hash SHA-256 de cada archivo de la copia. Sirve para detectar
  corrupción, truncamiento o una copia incompleta antes de confiar en ella.

`restaurar-estado.sh` ejecuta primero `sha256sum --check --quiet SHA256SUMS` y, si algo no cuadra,
se detiene sin borrar ni sustituir el volumen actual. Después muestra el manifiesto y pide
confirmación (o acepta `--si`). Está en `scripts/ops/restaurar-estado.sh`, líneas 12–20. La copia
de la Parte B tiene 545 MB y su manifiesto declara `tipo=copia en frío consistente (SHUTDOWN
IMMEDIATE)` y `archivos_fuera_del_volumen=0`.

### 3. Define RPO y RTO con los datos de tu propia copia.

- **RPO (Recovery Point Objective):** cuánto dato puedo perder como máximo. En el instante de la
  copia el RPO es **0**, porque la base se cerró limpiamente y todo lo confirmado está en la copia.
  A partir de la fecha del manifiesto, `2026-10-24 10:19:47 UTC`, el RPO crece con el tiempo: si el
  disco falla en el instante T, se pierde todo lo confirmado entre las 10:19:47 UTC y T.
- **RTO (Recovery Time Objective):** cuánto tardo en volver a tener servicio. Con esta copia hay que
  verificar los SHA-256, extraer 545 MB, recrear el contenedor, arrancar Oracle y esperar a que esté
  healthy. En este equipo son **pocos minutos**; el arranque tras recrear se observó healthy a los
  10 s y el script de espera permite hasta 600 s (`script/20261024T101824Z_00-backup-lab3.script.log`,
  líneas 67–71).

Para mejorar el RPO habría que aumentar la frecuencia de copia o combinar con `ARCHIVELOG` y copia
de archived logs; para mejorar el RTO, mantener la copia en disco rápido y automatizar la
restauración.

## 8.1.2 Diagnóstico y correcciones

### 4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro habría evitado el problema?

V000 creó los cinco datafiles con **nombres relativos** (`'academia01.dbf'`, `'clinica01.dbf'`, …).
Oracle resuelve un nombre relativo contra `$ORACLE_HOME/dbs`; en esta imagen ese directorio es un
symlink a `/opt/oracle/oradata/dbconfig/FREE/dbs`. Por eso aparecieron en
`/opt/oracle/product/26ai/dbhomeFree/dbs/…` (ruta real
`/opt/oracle/oradata/dbconfig/FREE/dbs/…`), fuera de la carpeta estándar
`/opt/oracle/oradata/FREE/FREEPDB1`.

La causa de fondo es que no había destino OMF: `db_create_file_dest` y `db_recovery_file_dest`
estaban vacíos. El parámetro que lo habría evitado es
**`DB_CREATE_FILE_DEST=/opt/oracle/oradata/FREE/FREEPDB1`** (o usar rutas absolutas en V000). Con
OMF, Oracle habría creado los archivos con nombres únicos en esa carpeta.

Evidencia: `script/20261024T102401Z_01-diagnostico.script.log`, líneas 21–31 (rutas), 36
(`db_create_file_dest` vacío) y 41–47 (symlink); `spool/20261024T111330Z_07-parametros-lectura.spool.log`,
línea 17, confirma que `db_create_file_dest` sigue vacío y es el valor por defecto.

### 5. ¿Por qué `ALTER TABLESPACE ... RENAME DATAFILE` no basta para mover un archivo?

Porque `RENAME DATAFILE` solo cambia el **puntero del control file** (y del diccionario); no mueve
ni copia los bytes. Si se renombra sin copiar el archivo, Oracle busca el datafile en la ruta nueva
y falla con `ORA-01157`/`ORA-01110` porque no lo encuentra. El movimiento real es una copia del
sistema operativo (o `DBMS_FILE_TRANSFER`/RMAN), y para que sea consistente se hace con el
tablespace `OFFLINE`; después se renombra, se pone `ONLINE` y solo cuando Oracle valida la cabecera
del archivo nuevo se borra el original.

En el laboratorio el orden fue: `OFFLINE` → `cp -p` → `ALTER TABLESPACE ... RENAME DATAFILE` →
`ONLINE` → borrar el original. Evidencia:
`script/20261024T102514Z_03-reubicar-datafiles.script.log`, líneas 8–29 (primer tablespace) y
126–130 (resultado final); la segunda ejecución no tiene nada que mover
(`script/20261024T102545Z_03-reubicar-datafiles-2.script.log`, línea 2).

### 6. ¿Por qué no se edita V000 y se crea V003? ¿Por qué invalidar una contraseña es mejor que borrarla del archivo?

No se edita V000 porque las migraciones son **historia inmutable**: V000 ya se aplicó, cambiar su
contenido provoca *checksum drift* y no borra la contraseña del historial de Git; además, otros
entornos quedarían divergentes. La corrección correcta es una migración nueva hacia adelante,
V003, que se aplica en orden y queda auditada.

Invalidar es mejor que borrar porque el secreto literal sigue en el historial de Git, en copias y
en logs. `NO AUTHENTICATION` convierte las cuentas en **schema-only**: siguen siendo dueñas de sus
objetos, pero nadie puede iniciar sesión con ellas, aunque alguien recupere la contraseña antigua.
La prueba con la contraseña vieja devuelve `ORA-01017`.
Evidencia: `database/migrations/V003__cuentas_esquema_sin_password.sql`, líneas 2–12;
`spool/20261024T102822Z_04-V003__cuentas_esquema_sin_password.spool.log`, líneas 20–26
(`AUTHENTICATION_TYPE=NONE`); `script/20261024T102844Z_04-prueba-password-invalida.script.log`,
línea 2 (`ORA-01017`); y `script/20261024T104159Z_04-revision-archivos.script.log`, líneas 1–5,
que muestra V000/V001 intactas y V003 añadida.

### 7. ¿Qué demuestra la prueba de persistencia y por qué se ejecuta después de reubicar?

Demuestra que la base vive en el **volumen de Docker**, no en la capa escribible del contenedor:
hace un cierre limpio, borra el contenedor, conserva el volumen `oralab-26ai-data`, recrea el
contenedor con la definición v2, espera a que esté healthy y comprueba que siguen los mismos cinco
tablespaces y las mismas tablas por owner. Los datos de negocio se cargan después con V002 (20.000
estudiantes, 40 asignaturas, 60.000 matrículas y la fila 101 en `ACTIVO`), así que la persistencia se
prueba con la estructura; si algún datafile estuviera fuera del volumen, `docker rm` lo habría
destruido.

Se ejecuta después de reubicar porque la reubicación es la que deja los cinco datafiles en
`/opt/oracle/oradata/FREE/FREEPDB1`, dentro del volumen y en la carpeta correcta. Hacer la prueba
antes no validaría la corrección y podría perder datos. Evidencia:
`script/20261024T104206Z_03-prueba-persistencia.script.log`, líneas 22–36 (cierre, borrado,
recreación y healthy a los 10 s), 37–57 (mismos tablespaces y conteos de tablas) y 58–60 (solo se
publica 1521). El propio script explica la dependencia en
`scripts/lab4/03-prueba-persistencia.sh`, líneas 2–5.

## 8.1.3 Instancia y arranque

### 8. Con tus evidencias: tres datos que pertenecen a la instancia y tres que pertenecen a la base de datos.

| Pertenece a | Dato | Valor | Evidencia |
|---|---|---|---|
| Instancia | `INSTANCE_NAME` / `HOST_NAME` | `FREE` / `7f9d45f8d577` | `spool/20261024T105323Z_05-instancia-y-base.spool.log`, línea 6 |
| Instancia | `STARTUP_TIME` | `2026-10-24 10:42:11` | mismo archivo, línea 6 |
| Instancia | SGA total | `1.603.398.928 bytes` | `script/20261024T105648Z_06-arranque-por-etapas.script.log`, línea 17 |
| Base de datos | `DBID` | `1509902213` | `spool/20261024T105323Z_05-instancia-y-base.spool.log`, línea 11 |
| Base de datos | `LOG_MODE` / `CREATED` | `ARCHIVELOG` / `2026-07-05` | mismo archivo, línea 11 |
| Base de datos | datafiles / tempfiles / redo / control | `16 / 3 / 3 / 2` | mismo archivo, líneas 30–33 |

Los datos de instancia desaparecen al apagar la instancia; los de base de datos siguen en disco y
sobreviven al apagado e incluso a la recreación del contenedor.

### 9. ¿Qué lee Oracle en NOMOUNT, en MOUNT y en OPEN? Relaciónalo con ORA-01507 y ORA-01219.

- **NOMOUNT:** lee el SPFILE/PFILE, reserva la SGA y arranca los procesos de background. Todavía no
  ha leído los control files. `v$parameter` funciona, pero `v$database` falla con **ORA-01507**
  (“database not mounted”).
- **MOUNT:** lee los control files y ya conoce el DBID, los datafiles, los redo logs y el modo de
  archivo. `v$database`, `v$datafile` y `v$controlfile` funcionan, pero los datafiles siguen
  cerrados: el diccionario no es accesible y `dba_tables` falla con **ORA-01219** (“queries allowed
  on fixed tables or views only”).
- **OPEN:** abre los datafiles y los redo logs online, hace recuperación de instancia si hace falta
  y abre el diccionario y las PDB. Ya funcionan `dba_tables` y las conexiones de usuario.

Evidencia: `script/20261024T105648Z_06-arranque-por-etapas.script.log`, líneas 14–40 (NOMOUNT y
ORA-01507), 44–67 (MOUNT y ORA-01219) y 71–89 (OPEN).

### 10. ¿Por qué FREEPDB1 se abre sola tras `ALTER DATABASE OPEN`? ¿Qué harías si no lo hiciera?

Porque su estado de apertura está **guardado** con `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE`.
Al abrir el CDB, Oracle consulta `dba_pdb_saved_states` y abre la PDB en el modo guardado
(`READ WRITE`). Evidencia:
`script/20261024T105648Z_06-arranque-por-etapas.script.log`, líneas 80–91 (FREEPDB1 en `READ WRITE`
y “abierta sola: el estado guardado funciona”); `script/20261024T105718Z_06-alert-log.script.log`,
línea 14 (“Completed: Pluggable database FREEPDB1 opened read write”).

Si no se abriera, desde `CDB$ROOT` ejecutaría:

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
```

La segunda orden es la que garantiza que se abra sola en el próximo arranque.

### 11. Clasifica ORA-00800 y ORA-20013 del alert log: ¿alerta real o ruido conocido? Justifícalo.

Ambas son **ruido conocido de contenedor**, no una alerta real de disponibilidad o corrupción:

- **ORA-00800** `[Set Priority Failed] [VKTM]/[LGWR]`: Oracle no puede fijar prioridades de tiempo
  real porque el contenedor no tiene `CAP_SYS_NICE`. Es un *soft external error*; la instancia
  arranca y funciona. Evidencia:
  `script/20261024T105718Z_06-alert-log.script.log`, líneas 2–3 y 28–29; el arranque por etapas
  termina en `OPEN` sin problema.
- **ORA-20013** de `DBMS_QOPATCH`: el inventario de parches no se puede leer dentro de la imagen de
  contenedor. Es una limitación conocida de la imagen, no un fallo de la base. En la ventana que
  capturamos no llegó a aparecer; el PDF lo documenta como el mismo tipo de ruido.

Una alerta real sería, por ejemplo, `ORA-00600`, `ORA-07445`, `ORA-01555`, `ORA-00257` o un error
de corrupción; esos sí exigirían investigación. Los `ORA-01507` y `ORA-01219` de la prueba de
etapas son **errores esperados** del ejercicio, no alertas.

## 8.1.4 Parámetros

### 12. Diferencia entre `v$parameter` y `v$spparameter` con el ejemplo de `db_files` de tu evidencia.

`v$parameter` muestra el valor **efectivo en memoria** de la instancia que está corriendo.
`v$spparameter` muestra lo que está **escrito en el SPFILE** (o si el parámetro no está
especificado). Con `db_files` se ve perfectamente:

1. `ALTER SYSTEM SET db_files = 300 SCOPE = SPFILE` deja `v$parameter` en **200** (la memoria no
   cambia) y `v$spparameter` en **300** (pendiente para el próximo arranque).
2. `ALTER SYSTEM RESET db_files` borra la línea del SPFILE: `v$parameter` sigue en 200 y
   `v$spparameter` pasa a `(no especificado)`; la verificación final lo confirma con
   `db_files_spfile=FALSE`.

Evidencia: `script/20261024T111334Z_07-parametros-cambios.script.log`, líneas 23–33;
`spool/20261024T111330Z_07-parametros-lectura.spool.log`, líneas 17 y 34–55; y
`script/20261024T113940Z_10-verificacion-final.script.log`, línea con
`db_files sin línea pendiente en el SPFILE (FALSE)`.

### 13. ¿Qué hace `SCOPE=BOTH` y cuál es el `SCOPE` por defecto con SPFILE?

`SCOPE=BOTH` cambia el parámetro **en memoria ahora** y **en el SPFILE** para que sobreviva al
reinicio. Con SPFILE, el `SCOPE` por defecto de `ALTER SYSTEM SET` es **`BOTH`**; con PFILE (sin
SPFILE) el defecto es `MEMORY`, porque no hay SPFILE que escribir. `SCOPE=MEMORY` se pierde al
reiniciar y `SCOPE=SPFILE` solo se aplica en el próximo arranque.

Evidencia: `script/20261024T111334Z_07-parametros-cambios.script.log`, líneas 2–12:
`open_cursors` pasa a 400 en memoria y sigue 300 en SPFILE con `SCOPE=MEMORY`; luego pasa a 500 en
memoria **y** en SPFILE con `SCOPE=BOTH` y comentario `Lab4: prueba SCOPE=BOTH`. Después se
deshace a 300.

### 14. ¿Por qué `PROCESSES` rechaza el cambio en memoria aunque `v$parameter` lo marque `IMMEDIATE`?

Porque `PROCESSES` dimensiona estructuras de la SGA y slots de procesos que se reservan al
**arrancar** la instancia; en la práctica es un parámetro **estático**. El metadato
`ISSYS_MODIFIABLE=IMMEDIATE` de esta imagen es engañoso: al ejecutar
`ALTER SYSTEM SET processes = 250 SCOPE = MEMORY` Oracle devuelve `ORA-02097` + `ORA-02095`
(“specified initialization parameter cannot be modified”). La lección es probar el cambio real, no
fiarse solo del diccionario. `db_files` es otro ejemplo de estático (`ORA-02095`), y `memory_size`
falla con `ORA-62352` si la instancia no arrancó con él.

Evidencia: `script/20261024T111334Z_07-parametros-cambios.script.log`, líneas 37–52;
`spool/20261024T111330Z_07-parametros-lectura.spool.log`, línea 27 (`processes` con
`SYS_MOD=IMMEDIATE`).

### 15. ¿Para qué sirve versionar el PFILE? Explica “configuration drift”.

Versionar el PFILE da una **foto legible y diffeable** de la configuración del SPFILE. Se genera con
`CREATE PFILE FROM SPFILE`; al estar en Git, cada cambio de parámetro queda revisable y se puede
comparar con el estado anterior. “**Configuration drift**” es la divergencia entre la configuración
real de la instancia y la que está documentada/versionada: alguien ejecuta un `ALTER SYSTEM` y
nadie lo registra; meses después nadie sabe por qué la instancia tiene ese valor. El PFILE en Git
hace visible esa deriva en un `git diff`.

Además sirve para recuperación: si el SPFILE se corrompe, se puede arrancar con
`STARTUP PFILE='/ruta/initFREE_lab4.ora'` y reconstruir el SPFILE con
`CREATE SPFILE FROM PFILE='...'`. Evidencia:
`script/20261024T111340Z_07-pfile.script.log`, líneas 1–3 (PFILE de 32 líneas versionado);
`config/initFREE_lab4.ora`; y `config/initFREE_lab4_memoria.ora` para el experimento de memoria.

## 8.1.5 Memoria y procesos

### 16. ¿Qué modelo de gestión de memoria usa tu instancia? Justifícalo con tres parámetros.

Usa **ASMM** (Automatic Shared Memory Management), no AMM:

- `memory_target = 0` y `memory_size = 0`: AMM está desactivada.
- `sga_target = 1536M` y `sga_max_size = 1536M`: Oracle reparte automáticamente los componentes de
  la SGA dentro de ese objetivo.
- `pga_aggregate_target = 512M`: la PGA se gestiona aparte, con su propio objetivo.

`db_cache_size = 0` y `shared_pool_size = 0` confirman que esos componentes se dejan autoajustar
dentro de `SGA_TARGET`. Evidencia:
`spool/20261024T111632Z_08-memoria.spool.log`, líneas 7–14 (parámetros), 29–52 (componentes y
ajustes dinámicos) y 70–76 (`v$pgastat`).

### 17. Explica las cifras de tu experimento de caché: lecturas lógicas, físicas y tasa de acierto.

La tabla `ACA_ESTUDIANTES` tiene 20.000 filas y ocupa **244 bloques** (245 contando la cabecera del
segmento). El experimento dio:

| Ronda | Filas | Lecturas lógicas | Lecturas físicas | Tasa de acierto |
|---|---:|---:|---:|---:|
| 1 (caché fría) | 17.600 `ACTIVO` | 463 | 272 | `1 − 272/463 ≈ 41,3 %` |
| 2 (caché caliente) | 17.600 `ACTIVO` | 247 | 0 | `1 − 0/247 = 100 %` |

La ronda 2 no genera lecturas físicas porque los bloques ya están en el buffer cache; `v$bh`
confirma **245 bloques** de la tabla en caché. Las lecturas lógicas de la ronda 1 son mayores que
las de la ronda 2 porque la primera consulta también lee cabecera de segmento, diccionario, undo y
las propias vistas `v$`; la tabla en sí son 245 bloques. Una lectura física siempre cuenta también
como lógica (el bloque se carga en caché y se lee), por eso lo que baja a 0 es la física, no la
lógica. Evidencia: `script/20261024T111641Z_08-experimento-cache.script.log`, líneas 6, 11–12 y
16–18.

### 18. ¿Por qué no se suma el RSS de los procesos para saber la memoria de la instancia?

Porque el RSS es la memoria **residente de cada proceso** y los procesos de Oracle comparten la SGA
(y páginas de código/bibliotecas) mediante memoria compartida. Al sumar el RSS de todos los
procesos se cuenta la misma página compartida una vez por proceso, así que el total sale inflado y
no representa la memoria física real de la instancia. Lo correcto es mirar `v$sga` + `v$pgastat`, o
el consumo del contenedor con `docker stats`. En la evidencia, `docker stats` muestra
**2,105 GiB** para todo el contenedor, mientras que la SGA son ~1,5 GB y la PGA en uso ~291,8 MB;
sumar los RSS de 57 procesos de background daría bastante más. Evidencia:
`script/20261024T105331Z_05-instancia-so.script.log`, líneas 21–23;
`spool/20261024T111632Z_08-memoria.spool.log`, líneas 18–23 y 70–73;
`spool/20261024T113202Z_09-procesos.spool.log`, líneas 7–9.

### 19. Relaciona el SPID de LGWR de `v$process` con el PID de `/proc`. ¿Por qué `docker top` muestra otro número?

`v$process.spid` de LGWR es **1588**. Dentro del contenedor, `/proc/1588` existe y `ps` muestra
`db_lgwr_FREE` con PID **1588**: coinciden porque ambos ven el **PID namespace del contenedor**.
`docker top` muestra los PIDs del **namespace del host** (por ejemplo, PMON 6109 y DBW0 6155), que
son otro número para el mismo proceso. No son procesos distintos: es el mismo proceso visto desde
dos namespaces de PID. Por eso, para correlacionar con `v$process` se usa `/proc` dentro del
contenedor; para herramientas del host se usa el PID de `docker top`. Evidencia:
`spool/20261024T113202Z_09-procesos.spool.log`, línea 19 (LGWR 1588);
`script/20261024T113207Z_09-procesos-so.script.log`, líneas 2–10 y 17–18;
`script/20261024T105331Z_05-instancia-so.script.log`, líneas 2–17 (PIDs del host).

### 20. ¿Qué hace PMON y qué hace SMON? Pon un ejemplo de cada uno.

- **PMON (Process Monitor):** limpia cuando un proceso de usuario termina de forma anormal. Hace
  rollback de la transacción del proceso muerto, libera sus locks y recursos y lo elimina de la
  lista de procesos. Ejemplo: se cae la conexión de SQLcl en medio de un `UPDATE`; PMON revierte el
  `UPDATE` no confirmado y libera las filas bloqueadas.
- **SMON (System Monitor):** se encarga del mantenimiento del sistema: recuperación de instancia
  al arrancar (roll forward de lo confirmado y rollback de lo no confirmado), coalescencia de
  extents libres y limpieza de segmentos temporales. Ejemplo: tras un `SHUTDOWN ABORT` o un fallo,
  SMON hace la recuperación en el siguiente `STARTUP` usando los redo logs online.

Evidencia: `spool/20261024T113202Z_09-procesos.spool.log`, líneas 15 (`PMON process cleanup`) y 17
(`SMON System Monitor Process`); `script/20261024T113207Z_09-procesos-so.script.log`, líneas 2 y 6
(PIDs 1534 y 1598). El alert log muestra la fase de `Crash Recovery` en el arranque
(`script/20261024T105718Z_06-alert-log.script.log`, líneas 8–9).

## 8.1.6 Seguridad y trabajo profesional

### 21. ¿Por qué `C##OPS_RO` y no `SYSTEM` para observar? ¿Qué no puede hacer `C##OPS_RO`?

`C##OPS_RO` es una cuenta **común de solo lectura** creada para observar: tiene únicamente
`CREATE SESSION`, `SET CONTAINER`, `SELECT_CATALOG_ROLE` y `CONTAINER_DATA=ALL`. Puede leer vistas
`V$`, metadatos `DBA_*`/`CDB_*` y consultar cualquier contenedor, pero **no puede** modificar datos
(no tiene `INSERT`/`UPDATE`/`DELETE`), crear o borrar objetos, crear usuarios, alterar la base,
cambiar parámetros ni gestionar archivos o backups. `SYSTEM` tiene privilegios DBA amplios; usarlo
para monitorizar rompe el principio de mínimo privilegio y, si se compromete la cuenta de
observación, el daño sería mucho mayor.

Evidencia: `scripts/lab4/02-cuenta-observabilidad.sql`, líneas 17–19 (solo esos grants);
`spool/20261024T105323Z_05-instancia-y-base.spool.log`, línea 16 (`C##OPS_RO` conectado en
`CDB$ROOT`); y `script/20261024T113940Z_10-verificacion-final.script.log`, línea
`C##OPS_RO es común (YES)`. La contraseña está en `config/.env` (ignorado por Git) y `ro.sh` la
pasa por entrada estándar, no por la línea de comandos.

### 22. ¿Qué dos vías de exposición de contraseñas corrige este laboratorio respecto al Lab 3?

1. **Contraseñas literales en V000**, versionadas en Git. V003 las invalida con `NO AUTHENTICATION`
   y convierte a los cinco propietarios en cuentas de solo esquema; la contraseña antigua ya no
   sirve (`ORA-01017`). Borrar las líneas de V000 no habría eliminado el secreto del historial.
2. **`sys/<contraseña>` en la línea de comandos** de `08-aplicar-migraciones.sh` v1, visible con
   `ps` y en el historial. La v2 usa autenticación del sistema operativo (`/ as sysdba`) y pasa la
   migración por entrada estándar; no hay contraseña en la línea de comandos.

Como mejora adicional, `05-crear-contenedor.sh` v2 ya no pasa `ORACLE_PWD` cuando el volumen ya
contiene la base, y `config/.env` está fuera de Git. Evidencia:
`script/20261024T104159Z_04-revision-archivos.script.log`, líneas 1–5 y 11–12;
`database/migrations/V003__cuentas_esquema_sin_password.sql`, líneas 2–12;
`spool/20261024T102822Z_04-V003__cuentas_esquema_sin_password.spool.log`, líneas 20–26;
`script/20261024T102844Z_04-prueba-password-invalida.script.log`, línea 2;
`scripts/deployment/env/08-aplicar-migraciones.sh`, líneas 3–5 y 19;
`scripts/deployment/env/05-crear-contenedor.sh`, líneas 6–7 y 15–23;
`.gitignore`, líneas 1–2; y `config/.env.example`, línea 8 (`OPS_RO_PWD=""`).

## Preguntas tipo examen P1–P12

### Clave rápida

| Pregunta | Respuesta | Tema |
|---|---|---|
| P1 | **A, D** | Copia en frío consistente |
| P2 | **B** | Mover datafile en Standard/Free |
| P3 | **A, C** | Datos de instancia vs. base de datos |
| P4 | **A, C** | Estado NOMOUNT |
| P5 | **B** | `ALTER DATABASE ARCHIVELOG` |
| P6 | **B** | `SCOPE` por defecto con SPFILE |
| P7 | **C** | Parámetro de instancia desde una PDB |
| P8 | **A, C** | Arrancar con PFILE y reconstruir SPFILE |
| P9 | **B** | ASMM y `DB_CACHE_SIZE` como mínimo |
| P10 | **A, D** | Componentes de la PGA |
| P11 | **C** | LGWR y `COMMIT` |
| P12 | **B, D** | Procesos obligatorios |

### P1 — Copia en frío tras `SHUTDOWN IMMEDIATE`

**Respuesta: A y D.**

`SHUTDOWN IMMEDIATE` hace checkpoint, cierra archivos y termina los procesos de forma limpia; la
copia de datafiles, control files y redo logs queda consistente y se puede restaurar y abrir con
`STARTUP` sin aplicar redo. B es falsa porque la copia en frío también es válida en `NOARCHIVELOG`;
C es falsa porque las transacciones en curso se revierten y el checkpoint deja los datafiles
consistentes; E es falsa porque RMAN no es obligatorio para una copia user-managed. Es exactamente
el tipo de copia de la Parte B (`00-backup-lab3.script.log`, líneas 59–65).

### P2 — Mover un datafile con una indisponibilidad breve

**Respuesta: B.**

El método correcto es poner el tablespace `OFFLINE`, copiar el archivo con el sistema operativo,
`ALTER TABLESPACE ... RENAME DATAFILE` y volver a `ONLINE`; es lo que hicimos en la Parte C.
A no es la respuesta esperada: `ALTER DATABASE MOVE DATAFILE` no está disponible en esta edición
Free (`ORA-00439`) y el escenario pide el método manual. C es falsa porque `RENAME DATAFILE` no
copia bytes; D es falsa porque `SHUTDOWN ABORT` no mueve nada y añade recuperación. Evidencia:
`03-reubicar-datafiles.script.log`, líneas 8–29.

### P3 — Datos de instancia y de base de datos

**Respuesta: A y C.**

`STARTUP_TIME` cambia en cada arranque, así que pertenece a la instancia; `CREATED` es la fecha de
creación de la base y no cambia, así que pertenece a la base de datos. B es falsa: el DBID no
cambia al recrear el contenedor si se conserva el volumen (en nuestra evidencia sigue siendo
`1509902213`). D es falsa: una instancia monta una sola base a la vez (en RAC son varias instancias
sobre una base, no al revés). E es falsa: `v$database` se puede consultar en `MOUNT`, como demuestra
la Parte E.

### P4 — Operaciones válidas en NOMOUNT

**Respuesta: A y C.**

En `NOMOUNT` la instancia ya está arrancada, con SGA y procesos, y ha leído el SPFILE/PFILE; por eso
`v$parameter` funciona y se puede ejecutar `CREATE CONTROLFILE` (que precisamente se usa cuando no
hay control file válido). `dba_users` necesita el diccionario abierto (`OPEN`), `ALTER DATABASE
ARCHIVELOG` necesita `MOUNT` y renombrar el datafile de `SYSTEM` también necesita `MOUNT`. Evidencia:
`06-arranque-por-etapas.script.log`, líneas 14–40.

### P5 — Estado para `ALTER DATABASE ARCHIVELOG`

**Respuesta: B (MOUNT).**

`ALTER DATABASE ARCHIVELOG` cambia el control file y el modo de los redo logs; por eso la base debe
estar montada, con los control files leídos, pero no abierta. En `NOMOUNT` no hay control file; en
`OPEN` habría que cerrar la base para cambiarlo. Evidencia: nuestra base está en `ARCHIVELOG`
(`05-instancia-y-base.spool.log`, línea 11) y el arranque por etapas muestra el modo en `MOUNT`
(`06-arranque-por-etapas.script.log`, línea 52).

### P6 — `ALTER SYSTEM SET open_cursors = 500;` con SPFILE

**Respuesta: B.**

Con SPFILE, el `SCOPE` por defecto es `BOTH`: el cambio se aplica en memoria y se escribe en el
SPFILE. A sería `SCOPE=MEMORY`; C sería `SCOPE=SPFILE`; D es falsa porque la cláusula `SCOPE` es
opcional. En la Parte F se ve el comportamiento: `open_cursors` pasa a 500 en memoria y en SPFILE
(`07-parametros-cambios.script.log`, líneas 8–12).

### P7 — `ALTER SYSTEM SET processes = 300 SCOPE = SPFILE;` desde FREEPDB1

**Respuesta: C.**

`PROCESSES` es un parámetro de **instancia**, no de PDB; desde una PDB Oracle devuelve
`ORA-65040: Operation is not allowed from within a pluggable database`. A es falsa porque el
parámetro no se aplica “solo a la PDB”; B es falsa porque no se aplica a toda la instancia desde la
PDB; D es falsa porque el error es `ORA-65040`, no `ORA-02095`. Evidencia:
`07-parametros-cambios.script.log`, líneas 56–66.

### P8 — Arrancar con un PFILE bueno y reconstruir el SPFILE

**Respuesta: A y C.**

`STARTUP PFILE='/ruta/init_bueno.ora'` arranca la instancia con ese PFILE, y
`CREATE SPFILE FROM PFILE='/ruta/init_bueno.ora'` reconstruye el SPFILE a partir del PFILE bueno.
B es falsa porque si la instancia no ha arrancado no se puede hacer `ALTER SYSTEM`; D y E no
reconstruyen el SPFILE. Es la utilidad de versionar el PFILE de la Parte F
(`07-pfile.script.log`, líneas 1–3).

### P9 — ASMM con `MEMORY_TARGET=0`, `SGA_TARGET=2G` y `DB_CACHE_SIZE=512M`

**Respuesta: B.**

Con `MEMORY_TARGET=0` no hay AMM; manda ASMM con `SGA_TARGET=2G`. `DB_CACHE_SIZE=512M` es un
**mínimo** para el buffer cache: Oracle puede ampliarlo, pero no bajarlo de 512M. A es falsa porque
no tiene por qué ser exactamente 512M; C es falsa porque AMM requiere `MEMORY_TARGET > 0`; D es
falsa porque `DB_CACHE_SIZE` no se ignora: actúa como suelo. En nuestra instancia se ve el modelo
ASMM en `08-memoria.spool.log`, líneas 7–14.

### P10 — Componentes de la PGA

**Respuesta: A y D.**

La PGA es memoria **privada** del proceso servidor: incluye el área de ordenación (`sort area`) y
la memoria de sesión. El shared pool, el log buffer y el buffer cache son componentes de la **SGA**,
no de la PGA. Evidencia: `08-memoria.spool.log`, líneas 66–76 (`v$pgastat`), y las secciones de SGA
en las líneas 16–52.

### P11 — Proceso que escribe los redo logs en un `COMMIT`

**Respuesta: C (LGWR).**

En un `COMMIT`, el servidor espera a que **LGWR** escriba el redo en los redo logs online (y
confirme el `COMMIT`) antes de responder al cliente. DBWn escribe bloques de datos sucios más tarde;
CKPT actualiza checkpoints; ARCn archiva redo; SMON hace recuperación. Evidencia:
`09-procesos.spool.log`, línea 19 (`LGWR Redo etc.`), y `09-procesos-so.script.log`, línea 4
(`db_lgwr_FREE`).

### P12 — Procesos de background obligatorios

**Respuesta: B y D (PMON y SMON).**

PMON y SMON son procesos obligatorios de la instancia: PMON limpia procesos de usuario y
transacciones muertas; SMON hace recuperación de instancia y mantenimiento. ARC0 solo existe en
`ARCHIVELOG` (aunque en nuestra instancia hay cuatro ARCn porque está en `ARCHIVELOG`); RECO solo
aparece si hay transacciones distribuidas; CJQ0 es el coordinador de colas de trabajos, no un
proceso obligatorio. Evidencia: `09-procesos.spool.log`, líneas 15–25.

## Verificación final

La comprobación automática del laboratorio terminó con:

```text
RESULTADO: TODO OK. Lab 4 listo para entregar.
```

Evidencia: `script/20261024T113940Z_10-verificacion-final.script.log`, última línea.

# Lab 5 — Respuestas, RTO/RPO y retrospectiva

**Alumno:** Israel Gallego — **Repositorio:** `oracle-database-lab`  
**Rama:** `chore/8-oracle-dba-workflow-ii` — **Issue:** #8  
**Ejecución:** 26-oct-2026 — **Cierre:** 27-oct-2026  
**Entorno:** Oracle AI Database 23.26.3, contenedor `oralab-26ai`, CDB `FREE`, PDB `FREEPDB1`, `ARCHIVELOG`, FRA de 4 GB, 3 control files, 3 grupos de redo con 2 miembros.

> Criterio: todas las cifras son las medidas en este entorno. Las citas `[E##]` remiten a la tabla de evidencias del final, con el nombre exacto del archivo. Cuando una cifra difiere de la salida ilustrativa del PDF se indica expresamente.

## 1. Preguntas de comprobación

### 1. Paso 6 de `lab4-final` frente a `lab3-final`

En mi copia `lab4-final`, el paso 6 dice `ninguno: el volumen contiene toda la base de datos` y el manifiesto confirma `archivos_fuera_del_volumen=0` [E00]. Mis dos copias `lab3-final` también tienen `archivos_fuera_del_volumen=0`, así que **en mi entorno no existe la diferencia de cinco datafiles fuera del volumen que describe el enunciado**. Lo que sí demuestra el paso 6 es que la copia en frío cubre todos los datafiles, control files, redo y SPFILE: no hay archivos externos que restaurar. Si el `lab3-final` de referencia tuviera cinco archivos fuera, la diferencia sería la reubicación del Lab 4; con mis datos no puedo atribuírmela.

### 2. Factor de bloqueo de CLIENTE y PEDIDO

Con `NUM_ROWS/BLOCKS`: CLIENTE = 100 000/1517 = **65,9 ≈ 66 filas/bloque**; PEDIDO = 1 000 000/5320 = **188 filas/bloque** [E01]. PEDIDO cabe 188/66 = **2,85 veces más**, porque su fila media es de **32 bytes** frente a **102 bytes** de CLIENTE (102/32 = 3,19); la diferencia entre 3,19 y 2,85 se explica por el overhead de bloque, `PCTFREE` y la variabilidad de las filas. Por eso el `bfr` calculado con `NUM_ROWS/BLOCKS` es una media: no todos los bloques tienen exactamente las mismas filas.

### 3. Por qué el banco mide la segunda ejecución

La primera ejecución puede incluir trabajo único: *hard parse*, lecturas físicas, limpieza de bloques, carga de la caché y calentamiento de la caché del cursor. La segunda refleja el coste estable en caliente y permite comparar **lecturas lógicas** de forma justa [E02]. Ejemplo: la búsqueda por `PK_PEDIDO` mide **4 buffers** en la segunda ejecución (3 del índice + 1 de tabla), no un valor contaminado por el primer acceso [E01b].

### 4. IX_PED_CLIENTE: altura, hojas y fan-out

`IX_PED_CLIENTE`: **altura 3**, **2216 hojas**, **1 000 000 de entradas**, **6 bloques de rama**; fan-out real = (2216 + 6 − 1)/6 = **370**; fan-out máximo = 8028/14,8 = **543** [E02]. Con 1 000 000 000 de filas serían **2 208 969 hojas** y **altura 4**: 5 lecturas lógicas para una fila (4 niveles de índice + 1 bloque de tabla). La altura crece con el logaritmo, no con el número de filas.

### 5. ROWID de una entrada de PK_CLIENTE

La primera entrada de la hoja de `PK_CLIENTE` guarda `data:(6): 00 00 03 1b 00 00`: **bloque 0x31B = 795**, **ranura 0** [E02]. No aparece el número de archivo porque el índice está en un tablespace *bigfile*: Oracle usa el ROWID corto de **4 bytes de bloque + 2 bytes de ranura**; el archivo es implícito (el tablespace bigfile tiene un único datafile). No es que el índice “no guarde” el archivo: lo representa de forma relativa.

### 6. Tres pruebas de la Parte D

- **Único (Q13):** sin índice, 1486 lecturas; con `UX_CLI_DNI`, **3 lecturas** y el plan `INDEX UNIQUE SCAN`. Gana porque la igualdad por DNI es muy selectiva y, además, la base garantiza el no-duplicado (`ORA-00001` al intentar insertar un DNI repetido) [E03].
- **Funcional (Q1):** `UPPER(email)` sin índice, 1486 lecturas; con índice funcional, **4 lecturas**. Gana porque el índice guarda el resultado de `UPPER(email)` y la consulta busca exactamente ese valor; la alternativa profesional es reescribir a `email = LOWER(:e)` y usar `UX_CLI_EMAIL` (también 4 lecturas, sin crear otro índice) [E03, E05].
- **Bitmap (Q14):** sin bitmaps, 4073 lecturas; con 4 bitmaps, **528 lecturas** y `BITMAP AND`. Gana en un almacén de datos con columnas de baja cardinalidad y filtros combinados; no se elegiría en el OLTP de TiendaSur porque un bitmap bloquea rangos de filas al modificarlas [E03].

### 7. Clustering factor de IX_PED_FECHA e IX_PED_CLIENTE

`IX_PED_FECHA` tiene CF = **5220** frente a **5320 bloques** de tabla: las fechas crecen y las filas vecinas del índice suelen estar en bloques vecinos. `IX_PED_CLIENTE` tiene CF = **999 041** frente a **1 000 000 de filas** y solo 5320 bloques: los clientes están repartidos aleatoriamente por los pedidos, así que cada entrada salta a un bloque distinto [E02, E04]. Un `REBUILD` **no** mejora el CF: el CF depende del orden físico de las filas de la tabla respecto de la clave, no de la fragmentación del índice. Para mejorarlo habría que reordenar la tabla o particionarla; para la consulta, un índice cubriente o aceptar el recorrido completo.

### 8. Punto de equilibrio medido

Con CF malo, el índice deja de compensar **entre el 0,1 % y el 0,2 %**: al 0,1 % el índice hace 975 lecturas frente a 5232 de la tabla; al 0,2 % el índice haría 2004, pero el optimizador ya elige el recorrido completo [E04]. La fórmula lógica da `k/r < 1/bfr = 1/188 = 0,53 %`; si la lectura aleatoria cuesta 5 veces más que la secuencial, baja a **0,11 %**, que es lo que se observa. Con CF bueno, al 50 % el índice aún gana (3938 < 5232) y al 100 % pierde (7875 > 5232): el cruce está entre el 50 % y el 100 %. Los tres puntos no coinciden porque el optimizador incorpora el coste relativo de lectura aleatoria y el CF, no solo el porcentaje de filas.

### 9. Q4b (`Gonz%`) usa el índice pero lee más que un full scan

Q4b devuelve 2056 filas y consume **2024 lecturas lógicas**; el recorrido completo de Q4a cuesta **1523** (la tabla tiene 1517 bloques) [E05]. El índice es sargable porque `Gonz%` es un rango, pero las filas de apellidos están dispersas: además de las hojas del índice hay que visitar un bloque de tabla por fila. Es un caso de índice selectivo “en teoría” pero mal agrupado; conviene medir y, si el full scan gana, forzarlo o replantear el índice.

### 10. Bloques modificados por INSERT con 4, 9 y 5 índices

- 4 índices: **20 306 bloques / 2000 filas = 10,2 bloques por fila**; 2586 KB de redo.
- 9 índices (propuesta del compañero): **40 321 / 2000 = 20,2 bloques por fila**; 4982 KB de redo.
- 5 índices (V005): **24 283 / 2000 = 12,1 bloques por fila**; 3183 KB de redo [E06].

Rechacé `IX_PED_CANAL` (3 valores, **33,3 % por valor**, ningún uso), `IX_PED_ESTADO` (4 valores, **25 %**; el 2 % de `P` se resolvió con el parcial `IX_PED_PENDIENTES`, 54 hojas y 20 000 entradas), `IX_PED_FEC_CLI` (sin uso y redundante con `IX_PED_FECHA`/`IX_PED_CLI_FEC_CUB`), `IX_PED_IMPORTE` (0 usos y CF 998 078) e `IX_PED_CLIENTE` (prefijo redundante de `IX_PED_CLI_FEC_CUB`). Conservé `IX_PED_CP` (0,009 % por valor), `IX_PED_FECHA` y `PK_PEDIDO`. El `IX_PED_CLI_FEC` de la propuesta se sustituyó por el cubriente `IX_PED_CLI_FEC_CUB` (40 MB, 3 lecturas en Q7): solo compensa porque Q7 se ejecuta 2000 veces/s.

### 11. Divisiones 50/50, 90/10 y patrón cola

- **50/50:** índice de claves aleatorias `IX_AZAR`: 595 divisiones, **0** al 90/10, 596 hojas, 336 entradas/hoja (≈69 % de llenado, cerca del `ln 2` teórico).
- **90/10:** `IX_CRECIENTE`: 398 divisiones, **las 398 al 90/10**, 399 hojas, 501 entradas/hoja; la hoja de la derecha se llena y se abre una nueva casi vacía.
- **Patrón cola:** `IX_COLA` tras insertar por un extremo y borrar por el otro: 425 hojas, **70 245 entradas borradas (41 %)**, 80 % de uso y **226 lecturas** para “el siguiente mensaje”, frente a 2 en el índice sano [E07a, E07b].

### 12. Remedio para el patrón cola en producción

Primero `ALTER INDEX ... COALESCE`: fusiona hojas medio vacías **en línea**, sin bloquear; en la prueba bajó de 425 a 201 hojas, las borradas de 70 245 a 0 y las lecturas de 226 a **2**, sin devolver espacio al tablespace [E07c]. Si hace falta recuperar disco, `SHRINK SPACE` (también en línea; 4 MB → 1,69 MB). `REBUILD ONLINE` solo con una causa medida: deja 223 hojas y 2 MB, pero necesita espacio doble y genera mucho redo. La cura de diseño es **particionar por fecha** y hacer `DROP`/`TRUNCATE PARTITION` de las particiones antiguas.

### 13. Qué compara Oracle al abrir la base

Compara el **SCN de checkpoint del control file** (`v$database.checkpoint_change#`) con el **SCN de la cabecera de cada datafile** (`v$datafile_header.checkpoint_change#`) [E08]. En la evidencia, todos los archivos abiertos estaban sincronizados en **5321351**; tras el checkpoint, en **5327763**. `PDB$SEED` se quedaba en 2098101 porque es de solo lectura y su checkpoint no avanza.

### 14. Qué protege la multiplexación en el mismo volumen

Con tres copias en `/opt/oracle/oradata/FREE` [E09b] protege frente a **corrupción lógica de una copia, borrado accidental o error humano**: si una falta o está dañada, se copia una sana y se monta. **No** protege frente a la pérdida del volumen o del disco, porque las tres están en el mismo fallo. En producción se ponen en discos/LUN distintos o en *failure groups* de ASM, se mantiene `CONTROL_FILES` en el SPFILE y se conserva un `BACKUP CONTROLFILE TO TRACE`; además se prueba la restauración.

### 15. CURRENT, ACTIVE e INACTIVE y los tres borrados rechazados

En el estado inicial [E10]: grupo 1 **CURRENT** (secuencia 13), grupos 2 y 3 **INACTIVE** (ya archivados). Tras el primer *switch*: grupo 1 **ACTIVE**, grupo 2 **CURRENT**, grupo 3 **INACTIVE**; tras el segundo: grupos 1 y 2 **ACTIVE**, grupo 3 **CURRENT**.

- **CURRENT:** LGWR está escribiendo en él; no se puede borrar el grupo (`ORA-01623`) ni un miembro (`ORA-01609`).
- **ACTIVE:** ya no es el actual, pero sus cambios aún no están todos en los datafiles; se necesita para la recuperación de instancia. No se puede borrar hasta checkpoint/archivado; el intento dio `ORA-00350` porque el grupo 1 necesitaba archivarse.
- **INACTIVE:** ya no se necesita para la recuperación de instancia; se puede borrar o limpiar si está archivado.

El caso “borrar otro grupo dejando uno solo” es ilustrativo con dos grupos; con mis tres grupos el rechazo real fue `ORA-00350` por el archivado pendiente. Además, `redo01b` quedó **INVALID** tras los dos *switches* porque el grupo 1 había sido el CURRENT al añadirlo; se valida cuando LGWR vuelve a escribir en ese grupo. El chequeo final cuenta miembros (`members < 2`), no el estado `INVALID`.

### 16. Cadena de la FRA llena

Con `db_recovery_file_dest_size = 2M`, los archivados llenan la FRA y aparece **ORA-19815** al 100 % (`2097152` bytes usados, 0 restantes) [E11]. Al pedir `ARCHIVE LOG CURRENT`, el log 2 secuencia 17 no puede archivarse: **ORA-16038** (“cannot be archived”) + **ORA-19809** (“limit exceeded for recovery files”); los grupos 2 y 3 quedan con `ARC=NO`. Si LGWR necesita reutilizar un grupo, las sesiones esperan en `log file switch (archiving needed)` y las nuevas conexiones pueden recibir **ORA-00257**; la base deja de aceptar cambios. La solución es devolver tamaño a la FRA (4 GB), con lo que ARCn archiva 2 y 3 automáticamente, o liberar espacio con RMAN; **nunca** borrar `.arc` con `rm`.

### 17. “Lectores no bloquean a escritores” con los pasos 1–4

Paso 1: B lee **ACTIVO** mientras A tiene un `UPDATE` a `EGRESADO` sin confirmar; B reconstruye el valor confirmado con el undo [E12]. Paso 2: la transacción de A consume **1 bloque de undo y 1 registro** (SID 21). Paso 3: A mantiene un bloqueo **TM modo 3** sobre `ACA_ESTUDIANTES` y **TX modo 6** sobre la fila. Paso 4: B intenta `FOR UPDATE WAIT 3` y recibe **ORA-00054**; el `SELECT` normal no esperó. Es decir, un lector normal no se bloquea por un escritor: lee la versión consistente del undo. Solo la escritura sobre la misma fila espera. Tras el COMMIT, B ve `EGRESADO`; el flashback a 40 s vuelve a ver `ACTIVO`; la reparación deja `ACTIVO` y `undo_retention=900` con 0 `ORA-01555`.

### 18. Por qué DELETE genera más undo y por qué el ROLLBACK genera redo

En 10 000 filas: INSERT deja **1136 KB** de undo; UPDATE, **1256 KB**; DELETE, **3416 KB** [E12b]. El INSERT solo necesita el ROWID para deshacer; el DELETE debe guardar la **fila completa y sus entradas de índice**. El ROLLBACK también genera redo: **357 KB** (INSERT), **2470 KB** (UPDATE) y **4701 KB** (DELETE), porque los bloques de undo son cambios protegidos por redo; deshacer es volver a aplicar cambios, no una operación gratuita.

### 19. Durabilidad tras COMMIT y tras checkpoint

Tras el COMMIT, la garantía está en el **redo online**: 8664 KB de redo, **9 escrituras de LGWR**, 231 bloques sucios de tabla y **0 bloques escritos por DBWn** [E13]. Los datafiles aún no tienen los cambios. Tras `ALTER SYSTEM CHECKPOINT`, DBWn escribe **623 bloques**, los sucios de la tabla bajan a **0** y el redo del checkpoint es de 14 KB; la recuperación de instancia será más corta, pero el redo y los archivados siguen siendo imprescindibles para una recuperación de medios.

### 20. Simulacro A: roll forward y roll back con 102 y 103

El alert log muestra `Beginning crash recovery`, `Recovery starting at checkpoint rba (logseq 19 block 68590), scn 5332311`, `read 19 KB redo, 16 data blocks need recovery`, `Completed crash recovery` y `Thread 1 opened at log sequence 20` [E14a]. SMON hace **roll forward** del redo desde el último checkpoint: rehace tanto el cambio confirmado de 102 (`EGRESADO`) como el no confirmado de 103 (`INACTIVO`). Después hace **roll back** con undo: deshace el cambio de 103 y lo devuelve a `ACTIVO`; 102 sigue `EGRESADO` porque estaba confirmado. El script devuelve 102 a `ACTIVO` para repetir el laboratorio.

### 21. RTO y RPO de los simulacros C y D

- **C (tabla borrada con PURGE, restauración completa):** RTO **56 s**; RPO **1 s artificial**, porque la copia se tomó justo antes del fallo y solo se perdió lo hecho en ese segundo. En un sistema real, el RPO de una copia en frío es el tiempo desde la última copia (horas o días). Se paró el contenedor, se sustituyó el volumen de 1,3 GB y se arrancó [E14c].
- **D (datafile 26 perdido, RMAN):** RTO **8 s** desde que el archivo se puso offline hasta que volvió online; **9 s desde el fallo**; RPO **0**, porque la copia RMAN + el redo archivado + el redo online contenían el cambio posterior de la fila 104, que seguía `EGRESADO` [E14d].

Son tan distintos porque C restaura **toda** la base y reinicia el contenedor, mientras D restaura **un solo datafile** y aplica redo con la PDB montada/abierta; D tiene mucho menos que copiar y no necesita volver a arrancar toda la instancia.

### 22. Clasificación de los ORA del bloque 5 del runbook

| ORA observado | Clasificación | Motivo |
|---|---|---|
| `ORA-01113` (file 31 needs media recovery) | Efecto del laboratorio (simulacro D) | Consecuencia de la recuperación del datafile 26 y de la PDB reabierta. |
| `ORA-01110` (data file 26) | Efecto del laboratorio (simulacro D) | `academia01.dbf` se borró a propósito. |
| `ORA-63999` (data file suffered media failure) | Efecto del laboratorio (simulacro D) | Oracle cerró `FREEPDB1` al detectar el archivo perdido. |
| `ORA-00800` (`Set Priority Failed`, LGWR/VKTM) | Ruido conocido | Aviso del contenedor por prioridades del sistema; se repite en arranques y no es un error de datos. |
| `ORA-00202` / `ORA-27037` (control03.ctl) | Efecto del laboratorio (simulacro B) | Se borró `control03.ctl` y se recuperó desde una copia sana. |
| `ORA-00205` / `ORA-205` al montar | Efecto del laboratorio (simulacro B) | Consecuencia esperada del control file ausente. |

No hay un incidente real nuevo: todos son consecuencia de los simulacros o ruido del contenedor. Si `ORA-00800` apareciera fuera del arranque, o surgiera un ORA no explicado por un simulacro, lo trataría como incidente y escalaría. [E15]

## 2. Simulacro de examen 1Z0-182 (S1–S26)

| # | Respuesta | Justificación y Parte |
|---|---|---|
| S1 | **B** | Con CF cercano a filas, un rango del índice visita casi un bloque distinto por fila (Parte E, [E04]). |
| S2 | **A, C** | Índice funcional sobre `UPPER(email)` o reescribir a `email = LOWER(:e)`; reconstruir o recoger estadísticas no elimina la función (Parte F, [E05]). |
| S3 | **B** | Oracle aplica `TO_NUMBER` a la columna y el índice está sobre el VARCHAR2 sin convertir (Parte F, [E05]). |
| S4 | **B** | Bitmap para baja cardinalidad y carga/consulta de almacén; en OLTP concurrente bloquea rangos (Parte D, [E03]). |
| S5 | **B** | `INDEX SKIP SCAN` recorre los pocos valores de `PAIS` y busca `CIUDAD` dentro de cada uno (Parte D, [E03]). |
| S6 | **B** | `INVISIBLE` mantiene el índice y permite volver a `VISIBLE` al instante; no se borra ni se bloquea (Parte G, [E06]). |
| S7 | **A, C** | `COALESCE` y `SHRINK SPACE` actúan en línea; `REBUILD` sin ONLINE y `MOVE` bloquean, y las estadísticas no liberan espacio (Parte H, [E07c]). |
| S8 | **B** | REVERSE reparte las inserciones secuenciales, pero al invertir la clave pierde los rangos (Parte H, [E07a]). |
| S9 | **C** | Un `UPDATE` de una columna no indexada no mantiene ningún índice; INSERT/DELETE/MERGE sí (Parte G, [E06]). |
| S10 | **B** | La altura depende del fan-out (entradas por bloque de rama) y del tamaño de la clave (Parte C, [E02]). |
| S11 | **A, C** | En una IOT las filas viven en el índice de la PK y una búsqueda por PK no accede a un segmento de tabla aparte; sí puede tener índices secundarios (Parte D, [E03]). |
| S12 | **B** | Compara el SCN de checkpoint del control file con el de la cabecera del datafile (Parte I, [E08]). |
| S13 | **C** | CKPT registra el checkpoint; DBWn escribe los bloques (Parte I/N, [E08], [E13]). |
| S14 | **B, E** | En NOMOUNT la instancia existe: funcionan `v$instance` y `v$parameter`; `v$database`/`v$logfile` requieren MOUNT y `dba_users`, OPEN (Parte I/J). |
| S15 | **B** | `SHUTDOWN IMMEDIATE; STARTUP MOUNT; ALTER DATABASE ARCHIVELOG; ALTER DATABASE OPEN` (Parte L, [E11a]). |
| S16 | **B** | Un grupo INACTIVE ya archivado se recrea con `ALTER DATABASE CLEAR LOGFILE GROUP n` (Parte K, [E10]). |
| S17 | **A, C** | Undo también da lectura consistente y consultas de flashback; no recupera medios ni archiva redo (Parte M, [E12]). |
| S18 | **B** | El undo se protege con redo para poder rehacerlo tras una caída antes de deshacer (Parte M, [E12b]). |
| S19 | **A** | El COMMIT garantiza el redo en el redo log online; no los datafiles, el archivado ni el checkpoint (Parte N, [E13]). |
| S20 | **A** | Menor `FAST_START_MTTR_TARGET` implica checkpoints incrementales más frecuentes y recuperación más rápida (Parte I/N). |
| S21 | **B** | ARCn no puede archivar (por ejemplo, FRA llena) y LGWR espera para reutilizar el grupo (Parte L, [E11b]). |
| S22 | **B** | Primero se pone el datafile de aplicación offline para mantener el resto del servicio; luego RESTORE/RECOVER/ONLINE (Parte O, [E14d]). |
| S23 | **B** | SYSTEM no se puede poner offline con la base abierta: SHUTDOWN ABORT, STARTUP MOUNT, RESTORE/RECOVER DATAFILE y OPEN (Parte O). |
| S24 | **B** | En NOARCHIVELOG solo se puede restaurar una copia en frío y se pierde lo posterior a ella (Parte L/O). |
| S25 | **B, D** | Aumentar `UNDO_RETENTION`/tamaño del undo y, si la consulta es crítica, `RETENTION GUARANTEE` (Parte M, [E12]). |
| S26 | **A** | `V$RECOVERY_AREA_USAGE` muestra el uso de la FRA por tipo de archivo (Parte L, [E11a]). |

## 3. Tabla RTO/RPO de los cuatro simulacros

| Simulacro | Fallo | RTO | RPO | Evidencia |
|---|---|---|---|---|
| **A** | `SHUTDOWN ABORT` (corte de luz) | No cronometrado aparte; `STARTUP` + *crash recovery* automático, `t=0` healthy | **0** (102 confirmado sobrevive; 103 no confirmado se deshace) | [E14a] |
| **B** | Pérdida de `control03.ctl` | No cronometrado aparte; parada + `ORA-00205` + copia sana + mount/open | **0** (no se pierde ningún dato) | [E14b] |
| **C** | `DROP TABLE ... PURGE` y restauración completa | **56 s** | **1 s artificial** (copia inmediatamente antes; en producción sería el tiempo desde la última copia en frío) | [E14c] |
| **D** | Pérdida del datafile 26 de `TBS_ACADEMIA` | **8 s** de offline a online; **9 s** desde el fallo | **0** (RMAN + redo archivado + redo online; 104 seguía `EGRESADO`) | [E14d] |

**Lección:** el RTO de C es alto porque se restaura toda la base; el de D es bajo porque solo se restaura un archivo y se aplica redo. El RPO de C es artificialmente bajo por la copia inmediata; un RPO real de 0 exige ARCHIVELOG + copias RMAN + redo, no una copia en frío ocasional.

## 4. Retrospectiva del game day

**Qué salió bien**

- Los cuatro simulacros se ejecutaron en el orden previsto y todos terminaron con la base `READ WRITE`, la PDB abierta y los datos restaurados.
- El runbook de pérdida de datafile cubre los dos caminos reales: PDB abierta (offline del archivo) y PDB cerrada por `ORA-63999` (restaurar con la PDB montada y abrirla después).
- La verificación final `16-verificacion-final.sh` terminó con **`RESULTADO: TODO OK`** y todas las evidencias 00–15 presentes [E16].
- El healthcheck como `C##OPS_RO` funciona en solo lectura y detecta FRA, control files, redo, RMAN, índices y undo sin privilegios de escritura [E15].

**Incidentes y aprendizajes**

1. **El grant del alert log faltaba.** El bloque 5 del healthcheck falló con `ORA-00942` porque `C##OPS_RO` no tenía `SELECT` sobre `V_$DIAG_ALERT_EXT`. Lo añadí al script de alta de la cuenta del Lab 4 (`02-cuenta-observabilidad.sql`) y lo verifiqué en `DBA_TAB_PRIVS`; ahora el chequeo final da `ops_ro_alert=1` y el healthcheck lee el alert log. No era un incidente nuevo: era una dependencia no documentada.
2. **La FRA llena avisa antes de bloquear.** El escenario de 2 MB produjo `ORA-19815` (aviso) antes de `ORA-16038/19809` (bloqueo). En producción hay que alertar al 80 % de la FRA y revisar `V$RECOVERY_AREA_USAGE`, no esperar al error.
3. **Tres copias del control file en el mismo volumen no protegen del disco.** El simulacro B demostró que se recupera de un borrado de una copia, pero un fallo del volumen se llevaría las tres. En producción: discos/LUN distintos o *failure groups* de ASM.
4. **Un miembro de redo puede quedar INVALID.** Tras añadir el segundo miembro y hacer dos *switches*, `redo01b` seguía INVALID porque el grupo 1 había sido el CURRENT; se valida cuando LGWR vuelve a escribir en ese grupo. El chequeo final cuenta miembros, no estados; un runbook debe vigilar `V$LOGFILE.STATUS`.
5. **La PDB se cierra sola con ORA-63999.** En el simulacro D, Oracle cerró `FREEPDB1` al detectar el datafile perdido. El procedimiento correcto fue esperar a MOUNTED, restaurar/recover y abrir; el RTO de 8 s incluye esa maniobra.
6. **El RPO de una copia en frío no es 0.** En C el RPO de 1 s es artificial porque la copia se hizo justo antes del fallo. En un sistema real, el RPO de una copia en frío es el tiempo desde la última copia; para RPO 0 hacen falta ARCHIVELOG y copias RMAN.
7. **La diferencia del paso 6 no se reprodujo.** Mis dos `lab3-final` ya tenían `archivos_fuera_del_volumen=0`; no puedo atribuir al Lab 4 una reubicación que mi entorno ya tenía. Lo dejo documentado para no presentar como medido algo que no lo está.

**Qué cambiaría del procedimiento**

- Añadir al healthcheck una alerta explícita al 80 % de la FRA y otra para miembros de redo en `INVALID`.
- Incluir el grant de `V_$DIAG_ALERT_EXT` en el alta base de `C##OPS_RO` (ya corregido) y probar el healthcheck en el CI.
- Separar las copias del control file en producción y documentar el `CONTROL_FILES` del SPFILE.
- Programar restauraciones de prueba periódicas: una copia que nunca se restaura no es una copia, es una esperanza.
- Para el RTO de C, evaluar RMAN `RECOVER TABLE` o copias incrementales, en lugar de restaurar toda la base por una tabla.
- Medir el RTO de A y B con cronómetro en la próxima iteración; en esta ocasión solo se registró que la recuperación fue automática e inmediata.

**Cierre**

El estado final queda con la base sana, V005 aplicada, 3 control files, 3 grupos de redo con 2 miembros, ARCHIVELOG, FRA de 4 GB, RMAN completado, `LAB5_PRUEBAS` ausente y la fila 101/102/104 en `ACTIVO`. La etiqueta `lab5-final` y su copia en `backups/` cierran el laboratorio.

## 5. Apéndice — checkpoints de las Partes

| Checkpoint | Respuesta | Nota breve |
|---|---|---|
| B1 | **B** | Faltan estadísticas/histograma en una columna sesgada; E-Rows 25 000 frente a A-Rows 20. |
| C1 | **C** | BLEVEL 2 ⇒ altura 3; 3 bloques de índice + 1 de tabla = 4 lecturas. |
| C2 | **C** | `1 + ceil(log_500(2 000 000)) = 4`. |
| D1 | **B** | Bitmap en cada columna de baja cardinalidad para el almacén. |
| D2 | **A, C** | Evita la tabla si solo usa columnas del índice; encarece INSERT/UPDATE de esas columnas. |
| E1 | **B** | CF ≈ filas y 3 % de filas: el recorrido completo es razonable. |
| F1 | **B** | `num_factura = 2025001` fuerza `TO_NUMBER` sobre la columna. |
| F2 | **A, C** | Rangos `>=` y `<` del día siguiente, o BETWEEN con el último segundo. |
| G1 | **B** | `INVISIBLE`: se mantiene y se puede revertir al instante. |
| G2 | **B** | Un índice más ≈ 2 bloques modificados por INSERT × 500/s = 1000/s. |
| H1 | **B** | `COALESCE` resuelve la cola en línea y con bajo coste. |
| H2 | **A, C** | Reparte la hoja caliente, pero no sirve para rangos/BETWEEN. |
| I1 | **B** | SCN de checkpoint del control file frente a la cabecera del datafile. |
| J1 | **B** | La instancia se detiene; se sustituye la copia dañada o se quita de `CONTROL_FILES` y se arranca. |
| J2 | **A, C** | Nombres/ubicaciones de datafiles y redo, y SCN del último checkpoint. |
| K1 | **C** | ACTIVE aún puede necesitarse para recuperación de instancia. |
| L1 | **B** | Hay que fijar antes `DB_RECOVERY_FILE_DEST_SIZE`; si no, ORA-19802. |
| L2 | **A, C** | Aumentar el tamaño de la FRA o copiar/borrar archivados con RMAN (`DELETE INPUT`). |
| M1 | **C** | B ve el valor confirmado anterior reconstruido con undo. |
| M2 | **C** | DELETE guarda la fila entera y sus índices; es el mayor undo. |
| M3 | **B, D** | Más `UNDO_RETENTION`/tamaño y `RETENTION GUARANTEE` si la consulta es crítica. |
| N1 | **A** | El redo de la transacción está en el redo log online. |
| N2 | **B, C** | Checkpoint y falta de buffers libres; no en cada COMMIT ni cada 3 s. |
| O1 | **B** | SMON aplica redo y deshace lo no confirmado; la base abre sin intervención. |
| O2 | **B, D** | Copiar una copia sana o quitar la perdida de `CONTROL_FILES` y montar. |
| O3 | **B** | Datafile offline, RESTORE, RECOVER, ONLINE; sin cerrar la base. |
| O4 | **D** | `PURGE` elimina la papelera; RMAN `RECOVER TABLE` recupera solo esa tabla. |

## 6. Desviaciones respecto a las cifras ilustrativas del PDF

| Punto | Enunciado (ilustrativo) | Medido en este entorno | Comentario |
|---|---|---|---|
| Estadísticas de CLIENTE | 1467 bloques / 98 B / bfr 68 | **1517 / 102 B / 66** | Depende de la carga y del `avg_row_len`; uso las cifras medidas [E01]. |
| Full scan Q13 | 1436 lecturas | **1486** | La tabla tiene 1517 bloques; el valor cambia con el estado de la caché [E03]. |
| Divisiones de hoja | 596 / 399 / 512 | **595 / 398 / 511** | Variación normal entre ejecuciones; el patrón 50/50, 90/10 y cola se mantiene [E07a]. |
| Siguiente mensaje en cola | 253 lecturas | **226** | El número exacto depende de las hojas vacías; el patrón y el remedio son los mismos [E07b]. |
| Coste de escritura | 10,1 → 12,2 bloques/fila | **10,2 → 12,1** | Dentro de la variabilidad; la conclusión (dos bloques por índice) no cambia [E06]. |
| Paso 6 de `lab3-final` | 5 datafiles fuera del volumen | **0** en mis dos copias | No reproduzco la diferencia; lo documento en la respuesta 1. |
| RTO de A y B | Cronometrado en el enunciado | **No cronometrado aparte**; recuperación automática/inmediata | En la próxima iteración se mide con cronómetro. |
| RPO de C | Bajo/artificial | **1 s artificial** | La copia se hizo inmediatamente antes del fallo. |
| Segundo miembro de redo | “Ninguno queda INVALID” | `redo01b` sigue **INVALID** tras dos switches | Con 3 grupos hace falta que el grupo 1 vuelva a ser CURRENT; el chequeo final cuenta miembros, no estados. |
| Error 4c de redo | ORA-01567 | **ORA-00350** | Con 3 grupos el intento no “deja uno solo”; Oracle rechaza por archivado pendiente. |

## 7. Evidencias citadas

| Clave | Archivo | Valor clave |
|---|---|---|
| E00 | `docs/bitacora/lab5/evidencia/script/20261026T151348Z_00-backup-lab4.script.log` | Paso 6: `ninguno: el volumen contiene toda la base de datos`. |
| E01 | `docs/bitacora/lab5/evidencia/script/20261026T151735Z_01-perfil-tiendasur.script.log` | CLIENTE 1517/102/66; PEDIDO 5320/32/188. |
| E01b | `docs/bitacora/lab5/evidencia/script/20261026T151735Z_01-herramienta-medir.script.log` | `prueba_pk` 4 lecturas lógicas. |
| E02 | `docs/bitacora/lab5/evidencia/script/20261026T151852Z_02-anatomia-indice.script.log` | IX_PED_CLIENTE altura 3, 2216 hojas, fo 370/543; ROWID 795/0. |
| E02b | `docs/bitacora/lab5/evidencia/config/20261026T151852Z_02-volcado-indice.trc.txt` | Volcado de hoja de PK_CLIENTE. |
| E03 | `docs/bitacora/lab5/evidencia/script/20261026T151913Z_03-tipos-indice.script.log` | Q13 1486→3; Q1 1486→4; Q7 15→7→3; Q14 4073→528. |
| E04 | `docs/bitacora/lab5/evidencia/script/20261026T151956Z_04-agrupamiento-equilibrio.script.log` | CF 5220/999041; curva de break-even. |
| E05 | `docs/bitacora/lab5/evidencia/script/20261026T152025Z_05-sargabilidad.script.log` | Q1 1486→4; Q3 5232→106; Q4b 2024. |
| E06 | `docs/bitacora/lab5/evidencia/script/20261026T152054Z_06-indices.script.log` | 4/9/5 índices: 10,2/20,2/12,1 bloques por fila; V005. |
| E07a | `docs/bitacora/lab5/evidencia/script/20261026T152133Z_07a-crecimiento.script.log` | 595/398/511 divisiones; 0/398/0 al 90/10. |
| E07b | `docs/bitacora/lab5/evidencia/script/20261026T152133Z_07b-patron-cola.script.log` | IX_COLA 425 hojas, 70 245 borradas (41 %), 226 lecturas. |
| E07c | `docs/bitacora/lab5/evidencia/script/20261026T152133Z_07c-remedios.script.log` | COALESCE 226→2; SHRINK 1,69 MB; REBUILD 223 hojas. |
| E08 | `docs/bitacora/lab5/evidencia/script/20261026T152218Z_08-scn-checkpoint.script.log` | SCN 5321351→5327763; PDB$SEED 2098101. |
| E09a | `docs/bitacora/lab5/evidencia/script/20261026T152334Z_09-controlfiles-info.script.log` | 2 copias iniciales; `control_file_record_keep_time=7`. |
| E09b | `docs/bitacora/lab5/evidencia/script/20261026T152337Z_09-multiplexar-controlfile.script.log` | 3 copias en `/opt/oracle/oradata/FREE`; bloqueo/arranque. |
| E10 | `docs/bitacora/lab5/evidencia/script/20261026T152417Z_10-redo.script.log` | Estados CURRENT/ACTIVE/INACTIVE; ORA-01623/01609/00350; `redo01b` INVALID. |
| E11a | `docs/bitacora/lab5/evidencia/script/20261026T152445Z_11-activar-archivelog.script.log` | FRA 4096 MB; ARCHIVELOG; ARC0–ARC3. |
| E11b | `docs/bitacora/lab5/evidencia/script/20261026T152502Z_11-fra-llena.script.log` | ORA-19815/16038/19809; 2 MB→4 GB; grupos 2/3 archivados. |
| E12 | `docs/bitacora/lab5/evidencia/script/20261026T152539Z_12-lectura-consistente.script.log` | B ve ACTIVO; 1 undo block; TM3/TX6; ORA-00054; flashback ACTIVO. |
| E12b | `docs/bitacora/lab5/evidencia/script/20261026T152613Z_12-undo-y-redo.script.log` | INSERT/UPDATE/DELETE undo 1136/1256/3416 KB; rollback redo 357/2470/4701 KB. |
| E13 | `docs/bitacora/lab5/evidencia/script/20261026T152640Z_13-lgwr-dbwn.script.log` | COMMIT 8664 KB/9 LGWR/231 sucios; checkpoint 623 DBWn/0 sucios. |
| E14a | `docs/bitacora/lab5/evidencia/script/20261026T152746Z_14a-caida-instancia.script.log` | 102 EGRESADO; 103 ACTIVO; 19 KB redo, 16 bloques; logseq 20. |
| E14b | `docs/bitacora/lab5/evidencia/script/20261026T152755Z_14b-perdida-controlfile.script.log` | ORA-00205/00202/27037; 3 copias restauradas. |
| E14c | `docs/bitacora/lab5/evidencia/script/20261026T152810Z_14c-simulacro-restauracion.script.log` | RTO 56 s; RPO 1 s; 60 000 matrículas. |
| E14d | `docs/bitacora/lab5/evidencia/script/20261026T153230Z_14d-perdida-datafile.script.log` | ORA-01116/01110/27041; ORA-63999; RTO 8/9 s; RPO 0; 104 EGRESADO. |
| E15 | `docs/bitacora/lab5/evidencia/spool/20261026T153630Z_15-healthcheck.spool.log` | Healthcheck completo; ORA-01113/01110/63999/00800/00202/205. |
| E16 | `docs/bitacora/lab5/evidencia/script/20261026T153703Z_16-verificacion-final.script.log` | `RESULTADO: TODO OK`. |

---

**Resultado de la verificación final:** `RESULTADO: TODO OK. Lab 5 listo para entregar.` [E16]

# Lab 6 — Administración operativa: respuestas

**Alumno:** Israel Gallego — **Repositorio:** `oracle-database-lab`  
**Rama:** `chore/10-administracion-operativa` — **Issue:** #10  
**Ejecución:** 23–24 de noviembre de 2026  
**Entorno:** Oracle AI Database 26ai, contenedor `oralab-26ai`, CDB `FREE`, PDB `FREEPDB1`

> Criterio: todas las cifras son las medidas en esta ejecución. Cada respuesta cita el archivo de evidencia y el valor exacto. Los archivos están en `docs/bitacora/lab6/evidencia/`.

## 1. Preguntas de comprobación

### Partes A-C · Rol operativo, parámetros y estados

#### 1. Errores ORA- en el alert log

> ¿Cuántos errores ORA- tenía tu alert log en 24 h en la Parte B y a qué se debían? ¿Por qué ese número no es una alarma por sí solo?

**Respuesta:**

4 errores; todos ORA-00800 de arranque (VKTM/LGWR), no de la aplicación; el número solo no distingue un error esperado de uno nuevo

**Evidencia:** `script/20261123T165134Z_01-turno.script.log` y `script/20261123T171423Z_02-estados-pdb.script.log`

#### 2. Ventana de mantenimiento del miércoles

> ¿A qué hora empieza y cuánto dura la ventana de mantenimiento de un miércoles en tu base? ¿Qué tareas automáticas corren en ella?

**Respuesta:**

WEDNESDAY_WINDOW, empieza a las 22:00 y dura 4 h; AutoTask: auto optimizer stats collection, auto space advisor y sql tuning advisor, los tres ENABLED

**Evidencia:** `spool/20261123T165748Z_01-automatizacion.spool.log`

#### 3. `V$SPPARAMETER` frente a `V$PARAMETER`

> Explica con tu salida de la Parte C la diferencia entre lo que mostraban V$SPPARAMETER y V$PARAMETER tras el SCOPE = SPFILE. ¿Qué habría pasado en el siguiente reinicio sin el RESET?

**Respuesta:**

SPFILE 250 con ISSPECIFIED TRUE; memoria 200; sin RESET, el próximo arranque leería 250

**Evidencia:** `script/20261123T171210Z_02-parametros.script.log`

#### 4. `RESET` de `db_files` frente a `processes`

> ¿Por qué RESET fue la vuelta atrás correcta para db_files y no lo habría sido para processes? Cita la línea de tu PFILE que lo demuestra.

**Respuesta:**

db_files no estaba fijado (FALSE); processes sí aparece como *.processes=200; RESET borra lo fijado, no devuelve un valor concreto

**Evidencia:** `script/20261123T171210Z_02-parametros.script.log` y `config/20261123T171320Z_02-init_desde_spfile.ora`

#### 5. Reinicio sin estado guardado

> Tras el reinicio sin estado guardado, ¿qué error obtuvo C##OPS_RO y por qué la instancia decía «Database opened»?

**Respuesta:**

ORA-01109 al entrar por el servicio; Database opened se refiere al CDB; FREEPDB1 quedó MOUNTED

**Evidencia:** `script/20261123T171423Z_02-estados-pdb.script.log`

### Partes D-E · Servicios, sesiones y diccionario

#### 6. SID, SPID y evento de la aplicación

> ¿Qué SID, SPID y evento tenía la sesión de la aplicación en tu ejecución? ¿Qué te dicen MODULE, ACTION y CLIENT_IDENTIFIER que no te diría USERNAME?

**Respuesta:**

SID 221, SPID 632, evento PL/SQL lock timer; MODULE=matriculas, ACTION=cierre-periodo, CLIENT_IDENTIFIER=ana.garcia@ucam

**Evidencia:** `script/20261124T142735Z_03-sesiones.script.log`

#### 7. `CANCEL SQL` frente a `KILL SESSION`

> Tras CANCEL SQL, ¿cuántas transacciones abiertas tenía la aplicación? ¿Y tras KILL SESSION? ¿En qué estado quedó la fila 101 y por qué?

**Respuesta:**

Tras CANCEL: 1 transacción abierta; tras KILL: 0; fila 101 en ACTIVO por el rollback

**Evidencia:** `script/20261124T142735Z_03-sesiones.script.log`

#### 8. `common_user_prefix`

> ¿Qué valor tiene common_user_prefix en tu imagen? ¿Qué implica para el nombre de una cuenta común?

**Respuesta:**

C##; las cuentas comunes deben empezar por C##; APP_ACADEMIA es local (COMMON=NO)

**Evidencia:** `script/20261124T142731Z_03-cuenta-app.script.log`

#### 9. Las tres miradas

> Completa con tus cifras la tabla de las tres miradas (ALL_TABLES, DBA_USERS, CDB_USERS, V$DATAFILE) y explica una diferencia.

**Respuesta:**

| Vista | CDB$ROOT | FREEPDB1 | APP_ACADEMIA |
|---|---:|---:|---:|
| `ALL_TABLES` de `ADMIN_ACADEMIA` |0|0|1|
| `ALL_USERS` |37|47|47|
| `DBA_USERS` |37|47|`ORA-00942`|
| `CDB_USERS` |37 y 47|47|`ORA-00942`|
| `V$DATAFILE` |17|10|`ORA-00942`|

_(explica aquí una diferencia con tus palabras)_

**Evidencia:** `script/20261124T143544Z_04-tres-miradas.script.log`

#### 10. Deltas de la carga

> Con tu salida de 04-deltas: ¿cuántas lecturas lógicas por recorrido y cuánto DB time costó la carga? ¿Qué indica la relación entre DB time y DB CPU?

**Respuesta:**

53286 lecturas lógicas, 5329 por recorrido; DB time .28 s, DB CPU .25 s; casi todo el tiempo es CPU

**Evidencia:** `script/20261124T143619Z_04-deltas.script.log`

### Partes F-G · Espacio y acceso

#### 11. Medidas de `TBS_ACADEMIA_HIST`

> Da las tres medidas (asignado, libre, máximo) de TBS_ACADEMIA_HIST antes de la carga y explica cuál usarías para alertar.

**Respuesta:**

10 MB asignados, 3.9 MB libres, 40 MB máximo; para alertar, el % sobre el máximo (15.16 %)

**Evidencia:** `script/20261124T143638Z_05-almacenamiento.script.log`

#### 12. `ORA-01950` y `ORA-01536`

> ¿Quién insertó y quién «pagó» en el ORA-01950? ¿Por qué ampliar el tablespace no habría resuelto el ORA-01536?

**Respuesta:**

El insert lo ejecuta el DBA, pero la cuota la paga CARGA_HIST, dueño del segmento; cuota de 2 MB; ampliar el tablespace no cambia la cuota

**Evidencia:** `script/20261124T143638Z_05-almacenamiento.script.log`

#### 13. Carga reanudable

> ¿Cuánto tiempo estuvo suspendida la carga reanudable y qué evidencia de ello dejó Oracle en el alert log?

**Respuesta:**

Suspendida de 14:36:42 a 14:36:57 (unos 15 s); el alert log deja was suspended due to y was resumed

**Evidencia:** `script/20261124T143642Z_05-resumable.script.log`

#### 14. Antes y después del `SHRINK`

> Antes y después del SHRINK: filas, bloques y cuota consumida. ¿Por qué un DELETE no devolvió el espacio?

**Respuesta:**

20000 filas / 2944 bloques / 23 MB → 2000 / 2944 / 23 MB → 2000 / 304 / 2.4 MB; el DELETE no baja la HWM

**Evidencia:** `script/20261124T143716Z_05-hwm-shrink.script.log`

#### 15. Perfil `DEFAULT` y `PRF_PERSONAS`

> ¿Qué valores tenía tu perfil DEFAULT? Justifica dos de los límites de PRF_PERSONAS para una persona de secretaría.

**Respuesta:**

DEFAULT: 10 intentos, 180 días, 7 de gracia, 1 de bloqueo, 365 de inactividad, verificación NULL; PRF_PERSONAS: 3 intentos, 1 minuto, 90 días, 90 de inactividad, ora12c_verify_function

**Evidencia:** `script/20261124T144154Z_06-gobierno-acceso.script.log`

#### 16. Ana lee `ACA_MATRICULAS`

> ¿Por qué Ana pudo leer ACA_MATRICULAS si nadie se la concedió por nombre? ¿Qué error obtuvo al cambiar el nombre de un alumno?

**Respuesta:**

SELECT ANY TABLE ON SCHEMA ADMIN_ACADEMIA; al cambiar el nombre, ORA-41900

**Evidencia:** `script/20261124T144159Z_06-probar-acceso.script.log`

### Partes H-I · Objetos, diagnóstico y guardia

#### 17. Invalidaciones por cambio de columna

> ¿Qué objetos se invalidaron en cada uno de los tres cambios de columna y por qué no se invalidó nada con la columna nueva?

**Respuesta:**

Columna nueva: nada; email_institucional: V_CONTACTO_LAB6; nombres: V_ACTIVOS_LAB6 y F_TOTAL_ACTIVOS_LAB6; dependencia de columna

**Evidencia:** `script/20261124T144231Z_07-objetos.script.log`

#### 18. Advisors de memoria

> Según tus advisors, ¿mejoraría el DB time duplicar la SGA? ¿Y por debajo de qué tamaño la PGA tendría sobreasignaciones?

**Respuesta:**

SGA de 1536 a 3072: factor 1 y 33249 lecturas, no mejora; PGA con sobreasignación: 5 con 128/256 MB, 1 con 384, 0 con 512

**Evidencia:** `spool/20261124T144239Z_07-memoria.spool.log`

#### 19. Traza de la consulta

> ¿Cuántas lecturas lógicas necesitó la consulta de la aplicación según la traza (o tkprof)? ¿Qué línea de la traza lo dice?

**Respuesta:**

247 lecturas lógicas; la línea FETCH ... cr=247

**Evidencia:** `script/20261124T144257Z_07-adr-trazas.script.log`

#### 20. Guardia: tres incidentes

> Para cada incidente de la guardia: evidencia clave, intervención y validación (una línea por cada uno).

**Respuesta:**

| Incidente | Evidencia clave | Intervención | Validación |
|---|---|---|---|
| INC-601 |APP_ACADEMIA SID 213, SERIAL# 60858, evento PL/SQL lock timer, módulo matriculas, acción cierre-periodo; ANA_GARCIA SID 223, evento enq: TX - row lock contention, blocking_session=213. Sección 2: fila 5 del bloque (estudiante 101). Sección 3: TX 196631/719, lmode 6 frente a request 6. Sección 4: 1 bloque y 1 registro de undo.|ALTER SYSTEM KILL SESSION '213,60858' IMMEDIATE; (el ORA-00031 es normal: la sesión queda marcada para morir).|fila 101 en ACTIVO; después no quedaban sesiones de APP_ACADEMIA ni de ANA_GARCIA.|
| INC-602 |base abierta y sin bloqueos; sección 6: FREEPDB1 en SI, academia_app en NO; el listener no anunciaba el servicio.|DBMS_SERVICE.START_SERVICE('academia_app') y ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;.|lsnrctl status muestra academia_app READY; 06-app-sigue.sql entra con ROL_APP_ACADEMIA, lee 17600 estudiantes y actualiza 1 fila (con el ORA-00942 esperado en CARGA_HIST).|
| INC-603 |APP_ACADEMIA en LOCKED (no LOCKED(TIMED)), bloqueo del 2026-11-24 14:59, perfil DEFAULT, 10 intentos permitidos; nota del script trimestral de bajas.|ALTER USER app_academia ACCOUNT UNLOCK;.|06-app-sigue.sql vuelve a entrar, lee 17600 estudiantes y actualiza 1 fila.|

**Evidencia:** `script/20261124T144919Z_08-diagnostico-1.script.log`, `script/20261124T145854Z_08-diagnostico-2.script.log` y `script/20261124T145937Z_08-diagnostico-3.script.log`

## 2. Simulacro de examen 1Z0-182

Rellena la letra y la Parte del laboratorio donde comprobaste cada respuesta. Las preguntas con «Elige dos» admiten dos letras.

| # | Tema | Letra | Parte |
|---|---|---|---|
| S1 | Proceso que genera las alertas de umbral de espacio |B|B|
| S2 | Parámetro con `ISSYS_MODIFIABLE = DEFERRED` |C|C|
| S3 | Copia de texto de los parámetros en uso |B|C|
| S4 | PDB en `READ ONLY` que pasa a `READ WRITE` (elige dos) |B,C|C|
| S5 | Vista con el estado guardado de cada PDB |C|C|
| S6 | PDB en modo restringido sin `RESTRICTED SESSION` |B|C|
| S7 | Paquete que crea y arranca un servicio |A|D|
| S8 | Columnas que unen `V$SESSION` con `V$PROCESS` |B|D|
| S9 | Efecto de `CANCEL SQL` en la transacción pendiente |C|D|
| S10 | `SHOW USER` conectado como `SYSOPER` |C|D|
| S11 | Métricas del último minuto de una PDB |B|E|
| S12 | Componentes que suma DB time (elige dos) |A,C|E|
| S13 | Quién necesita cuota en `ORA-01950` |B|F|
| S14 | Tablespaces sobre los que no se puede conceder cuota (elige dos) |A,C|F|
| S15 | Sesión `RESUMABLE` sin cuota (elige dos) |A,C|F|
| S16 | Requisito previo de `ALTER TABLE ... SHRINK SPACE` |B|F|
| S17 | `FAILED_LOGIN_ATTEMPTS 3` y `PASSWORD_LOCK_TIME 1` |B|G|
| S18 | Revocación de un privilegio concedido `WITH ADMIN OPTION` |B|G|
| S19 | Acciones que dejan un índice `UNUSABLE` (elige dos) |A,B|H|
| S20 | Traza de la sesión de otro usuario por SID y SERIAL# |B|H|
| S21 | Parámetro que fija la raíz del ADR |C|H|
| S22 | Primer paso ante `enq: TX - row lock contention` |C|I|

## 3. Mapa de evidencias

| # | Pregunta | Evidencia | Datos que debes citar |
|---|---|---|---|
| 1 | Errores ORA- en 24 h | `script/20261123T165134Z_01-turno.script.log`<br>`script/20261123T171423Z_02-estados-pdb.script.log` | **4** en 24 h; el desglose disponible muestra solo errores de arranque/reapertura: `ORA-00800` (**8**) y `ORA-65019` (**2**); ninguno es de la aplicación; el número aislado no distingue un error esperado de uno nuevo ni dice la causa |
| 2 | Ventana del miércoles | `spool/20261123T165748Z_01-automatizacion.spool.log` | `WEDNESDAY_WINDOW`: empieza a las **22:00** (`byhour=22`), dura **4 h**, `ENABLED=TRUE`; AutoTask `auto optimizer stats collection`, `auto space advisor` y `sql tuning advisor`, los tres `ENABLED` |
| 3 | `V$SPPARAMETER` vs `V$PARAMETER` | `script/20261123T171210Z_02-parametros.script.log` | SPFILE **250** con `ISSPECIFIED=TRUE`; memoria **200**; sin `RESET`, el próximo arranque habría leído **250** |
| 4 | `RESET` de `db_files` vs `processes` | `script/20261123T171210Z_02-parametros.script.log`<br>`config/20261123T171320Z_02-init_desde_spfile.ora` | `db_files` no estaba fijado (`FALSE`) y no aparece en el PFILE; `processes` sí aparece como `*.processes=200`; `RESET` borra lo fijado, no devuelve un valor concreto |
| 5 | Reinicio sin estado guardado | `script/20261123T171423Z_02-estados-pdb.script.log` | `ORA-01109: database not open` al entrar por el servicio; `FREEPDB1` quedó `MOUNTED`; «Database opened» se refiere al CDB |
| 6 | SID, SPID y evento | `script/20261124T142735Z_03-sesiones.script.log` | SID **221**, SPID **632**, evento `PL/SQL lock timer`; `MODULE=matriculas`, `ACTION=cierre-periodo`, `CLIENT_IDENTIFIER=ana.garcia@ucam` |
| 7 | `CANCEL SQL` vs `KILL SESSION` | `script/20261124T142735Z_03-sesiones.script.log` | Tras `CANCEL`: **1** transacción abierta; tras `KILL`: **0** sesiones y la fila 101 en `ACTIVO` por el rollback |
| 8 | `common_user_prefix` | `script/20261124T142731Z_03-cuenta-app.script.log` | `C##`; una cuenta común debe empezar por `C##`; `APP_ACADEMIA` es local (`COMMON=NO`) |
| 9 | Tres miradas | `script/20261124T143544Z_04-tres-miradas.script.log` | Root: `ALL_USERS` **37**, `DBA_USERS` **37**, `CDB_USERS` **37/47**, `V$DATAFILE` **17**; PDB: `ALL_USERS` **47**, `DBA_USERS` **47**, `CDB_USERS` **47**, `V$DATAFILE` **10**; `APP_ACADEMIA`: **1** tabla de `ADMIN_ACADEMIA` y `ORA-00942` en `DBA_USERS`, `CDB_USERS` y `V$DATAFILE` |
| 10 | Deltas | `script/20261124T143619Z_04-deltas.script.log` | **53286** lecturas lógicas, **5329** por recorrido; DB time **.28 s**, DB CPU **.25 s**; casi todo el tiempo es CPU |
| 11 | Tres medidas de `TBS_ACADEMIA_HIST` | `script/20261124T143638Z_05-almacenamiento.script.log` | **10 MB** asignados, **3.9 MB** libres, **40 MB** máximo; para alertar, **15.16 %** sobre el máximo (no el % sobre lo asignado) |
| 12 | `ORA-01950` y `ORA-01536` | `script/20261124T143638Z_05-almacenamiento.script.log` | El insert lo ejecuta el DBA, pero la cuota la paga `CARGA_HIST`, dueño del segmento; cuota de **2 MB** (`2097152` bytes); ampliar el tablespace no cambia la cuota |
| 13 | Carga reanudable | `script/20261124T143642Z_05-resumable.script.log` | Suspendida de **14:36:42** a **14:36:57** (unos **15 s**); el alert log deja `was suspended due to` y `was resumed` |
| 14 | Antes y después del `SHRINK` | `script/20261124T143716Z_05-hwm-shrink.script.log` | **20000** filas / **2944** bloques / **23 MB** → **2000** / **2944** / **23 MB** → **2000** / **304** / **2.4 MB**; el `DELETE` no baja la HWM |
| 15 | Perfil `DEFAULT` y `PRF_PERSONAS` | `script/20261124T144154Z_06-gobierno-acceso.script.log` | `DEFAULT`: **10** intentos, **180** días de vida, **7** de gracia, **1** de bloqueo, **365** de inactividad, verificación `NULL`; `PRF_PERSONAS`: **3** intentos, **1 minuto** de bloqueo, **90** días, **90** de inactividad, `ora12c_verify_function` |
| 16 | Ana lee `ACA_MATRICULAS` | `script/20261124T144159Z_06-probar-acceso.script.log` | `SELECT ANY TABLE ON SCHEMA ADMIN_ACADEMIA` concedido a `ROL_LECTURA_ACADEMIA`; al cambiar el nombre, `ORA-41900` (missing UPDATE privilege) |
| 17 | Invalidaciones | `script/20261124T144231Z_07-objetos.script.log` | Columna nueva: nada; `email_institucional`: `V_CONTACTO_LAB6`; `nombres`: `V_ACTIVOS_LAB6` y `F_TOTAL_ACTIVOS_LAB6`; dependencia de columna |
| 18 | Advisors | `spool/20261124T144239Z_07-memoria.spool.log` | SGA de 1536 a 3072: factor **1** y **33249** lecturas, no mejora; PGA: **5** sobreasignaciones con 128 y 256 MB, **1** con 384, **0** con 512 |
| 19 | Traza de la consulta | `script/20261124T144257Z_07-adr-trazas.script.log` | **247** lecturas lógicas; la línea `FETCH ... cr=247` (y tkprof: `Fetch 2 ... query 247`) |
| 20 | Guardia | `script/20261124T144919Z_08-diagnostico-1.script.log`<br>`script/20261124T145854Z_08-diagnostico-2.script.log`<br>`script/20261124T145937Z_08-diagnostico-3.script.log` | INC-601: bloqueador **213/60858**, `KILL`, fila 101 `ACTIVO`; INC-602: `academia_app NO`, `START_SERVICE` + `SAVE STATE`, listener `READY`; INC-603: `LOCKED`, `ACCOUNT UNLOCK`, app OK |

## 4. Cierre

- **Verificación final:** `bash scripts/lab6/09-verificacion-final.sh` → `TODO OK`.
- **Declaración de uso de IA:** `docs/bitacora/lab6-ia.md` (9 entradas).
- **Postmortems:** `docs/bitacora/lab6-guardia.md` (INC-601, INC-602, INC-603).

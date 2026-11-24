He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E022

<!-- Revisa y reescribe el campo «Qué hace» con tus palabras antes de entregar: el control de autoría te preguntará por él. -->

## Entrada 1
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Tengo que realizar esta tarea de administracion de base de datos "C:\Users\Irene\Downloads\P2_Lab 6 Oracle DBA Operations v1.2 - Estudiante.pdf" el profesor me ha dado esta carpeta tambien "C:\Users\Irene\Downloads\P2_Lab6_v1.3_Estudiante" este es el directorio de github en el que lo he hecho todo https://github.com/igallego9-stack/oracle-database-lab. No quiero que hagas tu el laboratorio, quiero que me digas que comandos tengo que ir utilizando y yo los voy ejecutando.
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
KIT=/mnt/c/Users/Irene/Downloads/P2_Lab6_v1.3_Estudiante/repo-kit
cp -r "$KIT/scripts/." scripts/
cp -r "$KIT/config/." config/
mkdir -p docs/plantillas
cp -r "$KIT/docs/plantillas/." docs/plantillas/
source scripts/deployment/env/00-config.sh
mkdir -p "$EVID_LAB6"/{script,spool,config}
chmod +x scripts/lab6/*.sh scripts/ops/*.sh
grep -q APP_ACADEMIA_PWD config/.env || printf 'APP_ACADEMIA_PWD=""\nANA_GARCIA_PWD=""\n' >> config/.env
grep -q '^ESTUDIANTE=' config/.env || echo 'ESTUDIANTE=""' >> config/.env
bash scripts/ops/alumno.sh
bash scripts/ops/backup-estado.sh lab6-inicio | tee "$EVID_LAB6/script/$(ts)_00-backup-lab6-inicio.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte A (preparación del entorno, copia del kit, configuración de las cuentas y evidencia 00).
- **Propósito (para qué lo necesitaba):** Preparar el entorno del Lab 6, copiar el kit, configurar las variables de las cuentas nuevas y del código de alumno, y generar la copia de seguridad del punto de partida sin equivocarme con las rutas.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero copié al repositorio los scripts, la configuración y las plantillas del kit, y creé las carpetas donde iba a guardar la evidencia. Después puse en config/.env mi código de alumno, E022, y las contraseñas de las dos cuentas nuevas, y ejecuté alumno.sh para que el prompt de SQLcl mostrara ese código. Por último, ejecuté backup-estado.sh para parar la base, copiar el volumen y volver a arrancarla, y así dejar guardado el estado inicial en la evidencia 00.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261123T163920Z_00-backup-lab6-inicio.script.log

## Entrada 2
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Tengo que realizar esta tarea de administracion de base de datos "C:\Users\Irene\Downloads\P2_Lab 6 Oracle DBA Operations v1.2 - Estudiante.pdf" el profesor me ha dado esta carpeta tambien "C:\Users\Irene\Downloads\P2_Lab6_v1.3_Estudiante" este es el directorio de github en el que lo he hecho todo https://github.com/igallego9-stack/oracle-database-lab. No quiero que hagas tu el laboratorio, quiero que me digas que comandos tengo que ir utilizando y yo los voy ejecutando.
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
source scripts/deployment/env/00-config.sh
bash scripts/ops/ro.sh scripts/ops/turno.sql | tee "$EVID_LAB6/script/$(ts)_01-turno.script.log"
bash scripts/ops/ro.sh scripts/lab6/01-automatizacion.sql freepdb1
```
- **Dónde lo usé (parte, script o pregunta):** Parte B (lista de turno y revisión del mantenimiento automático).
- **Propósito (para qué lo necesitaba):** Ejecutar la lista de turno con la cuenta de solo lectura y entender qué tareas de mantenimiento, ventanas, umbrales, AWR y trabajos del Scheduler tiene Oracle sin que yo los lance.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero ejecuté la lista de turno con C##OPS_RO: siete consultas fijas para ver dónde estoy, cómo están la instancia y la base, si las PDB están abiertas, cuántos errores ORA- hay en 24 h, si algún tablespace pasa del 85 %, si hay bloqueos y si hay alertas pendientes. Después ejecuté el script de automatización conectado a FREEPDB1, que muestra las tareas que Oracle hace solo (AutoTask), las ventanas de mantenimiento, los umbrales de espacio, la configuración de AWR y los trabajos del Scheduler. Con eso vi que el mantenimiento está activo, que los tablespaces de negocio no tienen umbral de aviso y que los 4 errores ORA- de la línea base son ORA-00800 de arranque, no de la aplicación.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261123T165134Z_01-turno.script.log y docs/bitacora/lab6/evidencia/spool/20261123T165748Z_01-automatizacion.spool.log
## Entrada 3
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Tengo que realizar esta tarea de administracion de base de datos "C:\Users\Irene\Downloads\P2_Lab 6 Oracle DBA Operations v1.2 - Estudiante.pdf" el profesor me ha dado esta carpeta tambien "C:\Users\Irene\Downloads\P2_Lab6_v1.3_Estudiante" este es el directorio de github en el que lo he hecho todo https://github.com/igallego9-stack/oracle-database-lab. No quiero que hagas tu el laboratorio, quiero que me digas que comandos tengo que ir utilizando y yo los voy ejecutando.
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
source scripts/deployment/env/00-config.sh
bash scripts/lab6/02-pfile-so.sh preparar
bash scripts/ops/sysdba.sh scripts/lab6/02-parametros.sql "$EVID_LAB6/script/$(ts)_02-parametros.script.log"
bash scripts/lab6/02-pfile-so.sh comparar
bash scripts/lab6/02-estados-pdb.sh | tee "$EVID_LAB6/script/$(ts)_02-estados-pdb.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte C (parámetros, SCOPE, estados de FREEPDB1 y validación del arranque).
- **Propósito (para qué lo necesitaba):** Aprender dónde queda un cambio de parámetro (memoria, SPFILE o ambos), cómo deshacerlo y comprobar que una PDB está realmente arriba después de un reinicio, no solo que la instancia diga «Database opened».
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero creé la carpeta `/opt/oracle/oradata/lab6` dentro del contenedor y ejecuté el script de parámetros como SYSDBA. Ese script crea dos copias de texto de los parámetros, una desde el SPFILE y otra desde la memoria, para tener una red de seguridad. Luego muestra los tipos de parámetro y prueba tres cosas: que `db_files` no se puede cambiar en memoria (ORA-02095), que con `SCOPE=SPFILE` el archivo queda en 250 pero la memoria sigue en 200, y que desde la PDB no se puede cambiar `processes` (ORA-65040). Al final deshace el cambio de `db_files` con `RESET`. Después comparé las dos copias y guardé los PFILE en la evidencia. Por último, ejecuté el script de estados de la PDB, que la pasa por READ ONLY, RESTRICTED y sin estado guardado, reinicia la instancia dos veces y comprueba que con SAVE STATE vuelve sola; termina con `validar-arranque.sql`.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261123T171210Z_02-parametros.script.log, docs/bitacora/lab6/evidencia/config/20261123T171320Z_02-init_desde_spfile.ora, docs/bitacora/lab6/evidencia/config/20261123T171320Z_02-init_desde_memoria.ora y docs/bitacora/lab6/evidencia/script/20261123T171423Z_02-estados-pdb.script.log
## Entrada 4
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Seguimos por donde lo dejamos, intenta darme el todos los codigos de cada parte, porque sino se me gastan los mensajes que te puedo enviar antes de que termine la tarea
```
```text
Te adjunto lo que me ha mostrado de la parte C y D. Recuerda hacer tu las modificaciones del .md especificando que he hecho en cada parte con la IA.
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
bash scripts/ops/sysdba.sh scripts/lab6/03-servicio.sql "$EVID_LAB6/script/$(ts)_03-servicio.script.log"
bash scripts/lab6/03-cuenta-app.sh | tee "$EVID_LAB6/script/$(ts)_03-cuenta-app.script.log"
bash scripts/lab6/03-sesiones.sh | tee "$EVID_LAB6/script/$(ts)_03-sesiones.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte D (servicio `academia_app`, cuenta de aplicación y manejo de sesiones).
- **Propósito (para qué lo necesitaba):** Crear un servicio propio para la aplicación de matrículas, una cuenta local para ella y ver una sesión completa: cómo se identifica, cómo se cancela su llamada y cómo se termina de verdad, sin tocar la tabla de negocio.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** El primer intento del script del servicio falló porque en ese momento Docker no estaba integrado en WSL, así que lo repetí y ya funcionó. Ese script crea el servicio `academia_app` en FREEPDB1, lo arranca y guarda el estado de la PDB para que el servicio siga ahí tras un reinicio. Después ejecuté el script de la cuenta, que comprueba que el prefijo de usuarios comunes es `C##`, crea `APP_ACADEMIA` como usuario local (no común), le da los privilegios que necesita y lo deja abierto. Por último ejecuté el script de sesiones: primero enseña en el listener que `freepdb1` y `academia_app` están READY; luego la aplicación entra por `academia_app`, modifica la fila 101 sin confirmar y se queda dormida. Desde la raíz veo la sesión con SID 221, SERIAL# 809, SPID 632, MODULE `matriculas`, ACTION `cierre-periodo` y CLIENT_IDENTIFIER `ana.garcia@ucam`. Al hacer `CANCEL SQL` la llamada se corta con ORA-01013 pero la transacción sigue abierta (1), y al hacer `KILL SESSION ... IMMEDIATE` sale ORA-00031, la sesión desaparece, el UPDATE se deshace y la fila 101 vuelve a `ACTIVO`; la aplicación recibe ORA-00028 y ORA-03114. El alert log deja el registro del kill y, al final, la prueba con SYSOPER da ORA-00942 porque ese privilegio opera pero no ve `DBA_USERS`.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261124T142658Z_03-servicio.script.log (primer intento fallido por Docker), docs/bitacora/lab6/evidencia/script/20261124T142725Z_03-servicio.script.log, docs/bitacora/lab6/evidencia/script/20261124T142731Z_03-cuenta-app.script.log y docs/bitacora/lab6/evidencia/script/20261124T142735Z_03-sesiones.script.log
## Entrada 5
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Seguimos por donde lo dejamos, intenta darme el todos los codigos de cada parte, porque sino se me gastan los mensajes que te puedo enviar antes de que termine la tarea
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
bash scripts/lab6/04-tres-miradas.sh | tee "$EVID_LAB6/script/$(ts)_04-tres-miradas.script.log"
bash scripts/ops/ro.sh scripts/lab6/04-diccionario.sql
bash scripts/ops/sysdba.sh scripts/lab6/04-deltas.sql "$EVID_LAB6/script/$(ts)_04-deltas.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte E (las tres miradas al diccionario y la medida de deltas).
- **Propósito (para qué lo necesitaba):** Comprobar que la misma consulta devuelve cosas distintas según la identidad y el contenedor desde el que entro, y aprender a medir lo que cuesta una carga restando dos fotos en vez de mirar solo acumulados.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero ejecuté el script de las tres miradas, que lanza la misma consulta con tres identidades. Con C##OPS_RO en CDB$ROOT veo 37 usuarios, 37 y 47 en CDB_USERS y 17 datafiles; con el mismo usuario entrando por el servicio freepdb1 veo 47 usuarios, solo el contenedor 3 y 10 datafiles; y con APP_ACADEMIA por academia_app veo 1 tabla de ADMIN_ACADEMIA y 47 usuarios, pero DBA_USERS, CDB_USERS y V$DATAFILE me dan ORA-00942 porque esa cuenta no tiene privilegios de catálogo. Después ejecuté el script del diccionario: hay 1591 tablas X$, 921 vistas V$ y 880 GV$; V$INSTANCE es GV$INSTANCE filtrada por inst_id; DBA_USERS y V$SESSION son sinónimos públicos; DICTIONARY solo me lista 16 vistas DBA; DBA_TS_QUOTAS tiene MAX_BYTES = -1 cuando la cuota es ilimitada; y C##OPS_RO tiene CONTAINER_DATA con ALL_CONTAINERS = Y. Por último, el script de deltas: V$CON_SYSMETRIC sale a cero dentro de la PDB, el acumulado desde el arranque era DB time 6.3 s con 9 minutos arriba, y los 10 recorridos completos de PEDIDO costaron .27 s de reloj, .28 s de DB time, .25 s de DB CPU y 53286 lecturas lógicas (5329 por recorrido); las esperas eran User I/O 2.1 s, Concurrency .3 s, Scheduler .3 s y Other .2 s.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261124T143544Z_04-tres-miradas.script.log, docs/bitacora/lab6/evidencia/spool/20261124T143600Z_04-diccionario.spool.log y docs/bitacora/lab6/evidencia/script/20261124T143619Z_04-deltas.script.log

## Entrada 6
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Seguimos por donde lo dejamos, intenta darme el todos los codigos de cada parte, porque sino se me gastan los mensajes que te puedo enviar antes de que termine la tarea
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
bash scripts/ops/sysdba.sh scripts/lab6/05-almacenamiento.sql "$EVID_LAB6/script/$(ts)_05-almacenamiento.script.log"
bash scripts/lab6/05-resumable.sh | tee "$EVID_LAB6/script/$(ts)_05-resumable.script.log"
bash scripts/ops/sysdba.sh scripts/lab6/05-hwm-shrink.sql "$EVID_LAB6/script/$(ts)_05-hwm-shrink.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte F (tablespace con techo, cuotas, carga reanudable y HWM).
- **Propósito (para qué lo necesitaba):** Ver la diferencia entre lo asignado, lo libre y el máximo alcanzable de un tablespace, comprobar quién paga la cuota cuando se inserta, convertir un fallo de espacio en una pausa con RESUMABLE y entender por qué borrar filas no devuelve espacio hasta bajar la HWM.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero creé TBS_ACADEMIA_HIST con un datafile de 10 MB, autoextend de 5 MB y MAXSIZE 40 MB, y medí los tres números: 10 MB asignados, 3.9 MB libres dentro de lo asignado y 40 MB como máximo alcanzable; de los 5120 bloques máximos, 776 usados (15.16 %). TBS_ACADEMIA ya existía con 100 MB y máximo 1024 MB. Luego creé el esquema CARGA_HIST sin cuota: la tabla se creó sin segmento (0 segmentos), el primer INSERT dio ORA-01950 y, al ponerle 2 MB de cuota, un INSERT de 5000 filas dio ORA-01536; la cuota quedó en 2097152 bytes y 256 bloques. También probé que no se puede poner cuota sobre TEMP (ORA-30041) y puse el umbral de aviso 80/95 en TBS_ACADEMIA_HIST, que antes estaba en NONE. Después ejecuté la carga reanudable: el script dio permisos temporales de INSERT y RESUMABLE a APP_ACADEMIA (la deuda que se paga en la Parte G) y lanzó 20000 filas con RESUMABLE; a los 12 s la sesión 213 estaba SUSPENDED con ORA-01536, timeout 180 y el evento «statement suspended, wait error to be cleared». En vez de tocar el tablespace, subí la cuota de CARGA_HIST a 30 MB y la carga se reanudó sola: terminó con 20000 filas entre 14:36:42 y 14:36:57, usando 23 MB de los 30 MB. Por último, el script de HWM: antes del DELETE había 20000 filas en 2944 bloques (23 MB); tras borrar 18000 seguían 2944 bloques y 23 MB, así que activé ROW MOVEMENT y ejecuté SHRINK SPACE, que bajó a 304 bloques y 2.4 MB, con la cuota usada en 2.4 MB.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261124T143638Z_05-almacenamiento.script.log, docs/bitacora/lab6/evidencia/script/20261124T143642Z_05-resumable.script.log y docs/bitacora/lab6/evidencia/script/20261124T143716Z_05-hwm-shrink.script.log
## Entrada 7
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Seguimos por donde lo dejamos, intenta darme el todos los codigos de cada parte, porque sino se me gastan los mensajes que te puedo enviar antes de que termine la tarea
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
bash scripts/lab6/06-gobierno-acceso.sh | tee "$EVID_LAB6/script/$(ts)_06-gobierno-acceso.script.log"
bash scripts/lab6/06-probar-acceso.sh | tee "$EVID_LAB6/script/$(ts)_06-probar-acceso.script.log"
bash scripts/lab6/06-cascada.sh | tee "$EVID_LAB6/script/$(ts)_06-cascada.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte G (perfil de personas, roles funcionales, cuenta nominal y pago de la deuda de acceso).
- **Propósito (para qué lo necesitaba):** Pasar de privilegios sueltos a roles funcionales, crear una cuenta nominal para Ana García, retirar los permisos temporales que quedaron de las Partes D y F y comprobar con las identidades reales qué puede y qué no puede hacer cada una.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero consulté el perfil DEFAULT para no suponer los valores: 10 intentos fallidos, 180 días de vida de contraseña, 7 de gracia, 1 de bloqueo, 365 de inactividad y función de verificación NULL. Luego creé PRF_PERSONAS con bloqueo de 1 minuto (solo para el laboratorio) y una función de verificación que rechaza contraseñas débiles: al probar «corta» dio ORA-28003 con el mensaje de menos de 8 caracteres. Después creé los roles funcionales ROL_LECTURA_ACADEMIA, ROL_SECRETARIA_ACADEMIA y ROL_APP_ACADEMIA, y los enlacé: ANA_GARCIA recibe ROL_SECRETARIA_ACADEMIA, que a su vez incluye ROL_LECTURA_ACADEMIA; APP_ACADEMIA recibe ROL_APP_ACADEMIA. ROL_LECTURA_ACADEMIA tiene SELECT ANY TABLE sobre ADMIN_ACADEMIA, ROL_APP_ACADEMIA tiene SELECT y UPDATE sobre ACA_ESTUDIANTES y ROL_SECRETARIA_ACADEMIA tiene UPDATE solo de la columna ESTADO. Con eso pagué la deuda: APP_ACADEMIA dejó de tener privilegios directos y permisos temporales, y se quedó solo con su rol. En la prueba, ANA_GARCIA entra por freepdb1 con sus dos roles y CREATE SESSION, lee 20000 estudiantes y 60000 matrículas, actualiza el ESTADO de un estudiante y deshace, pero no puede cambiar el nombre ni borrar (ORA-41900 en ambos casos). APP_ACADEMIA sigue viendo 17600 estudiantes y actualizando, pero ya no puede insertar en CARGA_HIST.REGISTRO (ORA-00942). Al fallar tres veces la contraseña de ANA sale ORA-01017 tres veces y luego ORA-28000; la cuenta queda LOCKED(TIMED) y el DBA la desbloquea. Por último, en la cascada, U6_A recibe CREATE SESSION con ADMIN OPTION y SELECT con GRANT OPTION, se los pasa a U6_B, y al revocar a U6_A el privilegio de sistema de U6_B sobrevive pero el de objeto cae en cascada; al final se borran los dos usuarios de prueba.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261124T144154Z_06-gobierno-acceso.script.log, docs/bitacora/lab6/evidencia/script/20261124T144159Z_06-probar-acceso.script.log y docs/bitacora/lab6/evidencia/script/20261124T144213Z_06-cascada.script.log

## Entrada 8
- **Herramienta:** OpenCode (DeepSeek V4.1 Flash Free)
- **Prompt (literal, copiado tal cual):**
```text
Seguimos por donde lo dejamos, intenta darme el todos los codigos de cada parte, porque sino se me gastan los mensajes que te puedo enviar antes de que termine la tarea
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
bash scripts/ops/sysdba.sh scripts/lab6/07-objetos.sql "$EVID_LAB6/script/$(ts)_07-objetos.script.log"
bash scripts/ops/ro.sh scripts/lab6/07-memoria.sql | tee "$EVID_LAB6/script/$(ts)_07-memoria.script.log"
bash scripts/ops/ro.sh scripts/lab6/07-archivos-criticos.sql | tee "$EVID_LAB6/script/$(ts)_07-archivos-criticos.script.log"
docker exec oralab-26ai ls -l /opt/oracle/product/26ai/dbhomeFree/dbs/
bash scripts/lab6/07-adr-trazas.sh | tee "$EVID_LAB6/script/$(ts)_07-adr-trazas.script.log"
```
- **Dónde lo usé (parte, script o pregunta):** Parte H (validez de objetos, memoria, archivos críticos y ADR).
- **Propósito (para qué lo necesitaba):** Ver que un cambio de columna invalida solo lo que la usa y que la recompilación puede esperar a hora punta, entender qué índices quedan UNUSABLE y qué ocupa la papelera, preguntar a los advisors antes de tocar memoria, inventariar los archivos que no pueden faltar y seguir una sesión concreta por el ADR.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Primero ejecuté el script de objetos, que trabaja sobre una copia ACA_EST_LAB6 y no sobre la tabla de negocio. Al añadir una columna que nadie usa no se invalida nada; al ampliar email_institucional solo queda INVALID V_CONTACTO_LAB6; al ampliar nombres caen V_ACTIVOS_LAB6 y, en cascada, F_TOTAL_ACTIVOS_LAB6. Cuando un usuario llama a la función, Oracle la recompila sola y también deja válida la vista, pero V_CONTACTO_LAB6 sigue inválida hasta que el DBA recompila el esquema antes de abrir el servicio; al final los inválidos de negocio son 0. El MOVE de la tabla deja el índice IX_EST_LAB6_ESTADO UNUSABLE sin dar error, y hay que reconstruirlo. En la papelera quedan un índice de .5 MB y la tabla de 2 MB, y la validación final da 0 inválidos. Después miré la memoria: SGA máxima 1529 MB, buffer cache 1056 MB, shared pool 432 MB, shared IO pool 80 MB fijado, large pool 16 MB y 16 MB libres; no hubo movimientos GROW/SHRINK. La PGA tiene target de 512 MB, 354 MB en uso, 418 MB asignados, máximo 549 MB, 0 sobreasignaciones y 100 % de acierto; los procesos que más consumen son ARC2 con 30.9 MB, M009 con 28.6 y BG01 con 22.5. El advisor de SGA dice que con 768 MB el factor de tiempo sube a 1.0233 y las lecturas físicas a 37246, mientras que de 1152 MB en adelante se queda en 1 y 33249; el de PGA dice que con 512 MB ya hay 100 % de acierto y 0 sobreasignación. Luego revisé los archivos críticos: tres control files, tres grupos de redo de 200 MB con dos miembros cada uno, spfile y password file en dbs, FRA con 331 de 4096 MB, ARCHIVELOG con 23 archivados y una copia RMAN del 24/11 a las 14:42 con 6 piezas; SYS es el único con SYSDBA y SYSOPER. El listado de dbs confirma spfileFREE.ora, orapwFREE, los archivos de control y los archivados antiguos. Por último, el ADR: base /opt/oracle, home /opt/oracle/diag/rdbms/free/FREE, 42 incidentes activos y 1 problema activo, el problema ORA 800 con 42 incidentes de «Set Priority Failed» entre el 5 de julio y el 24 de noviembre; el alert log está en texto y en XML, hay 680 trazas y ADRCI ve el problema. Para trazar la sesión 57,19918 usé DBMS_MONITOR y la traza salió en FREE_ora_1939_lab6_app.trc; en bruto se ven PARSING, EXEC, FETCH y un WAIT de «PL/SQL lock timer» de unos 8 s, y tkprof deja la consulta de activos en 247 lecturas lógicas y 1 fila.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261124T144231Z_07-objetos.script.log, docs/bitacora/lab6/evidencia/spool/20261124T144239Z_07-memoria.spool.log, docs/bitacora/lab6/evidencia/spool/20261124T144250Z_07-archivos-criticos.spool.log y docs/bitacora/lab6/evidencia/script/20261124T144257Z_07-adr-trazas.script.log

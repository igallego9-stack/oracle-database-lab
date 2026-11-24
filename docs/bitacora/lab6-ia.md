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

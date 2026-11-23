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

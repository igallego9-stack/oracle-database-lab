# Lab 3 — Respuestas de comprobación
## Docker
1. Imagen es plantilla (alpine:3.20, database/free:latest digest f988b0...); contenedor es instancia viva (prueba, oralab-26ai). En G2 hello-world creó contenedor Exited(0); en G4 run -it prueba sh te dejó dentro hasta exit.
2. G5 nota.txt en /tmp vivía en capa del contenedor, rm prueba lo borró. G6 en /datos vivía en volumen datos-prueba, sobrevivió a --rm.
3. ps solo Up, ps -a también Exited. Exited(0) terminó bien, Exited(1+) con error.
4. -p 8080:80 = tuyo:contenedor. Con -p 80:8080 nginx no escucha en 8080 y localhost:8080 no carga.
5. Oracle sigue Up porque su proceso (base) no termina; hello-world imprime y termina.
6. Digest sha256:f988b0... es huella exacta 13.8GB. :latest cambia con el tiempo, digest no.
7. docker volume rm oralab-26ai-data borra datos. docker rm oralab-26ai solo borra proceso, volumen queda.
## Git, organización y evidencia
8. Lo hago en oracle-database-lab con Issue #3, branch chore/3-install-oracle-environment y PR porque queda reproducible y revisable. En carpeta aparte perdería historial de Labs 1-2, protección de main y trazabilidad. Evita snowflake server.
9. source scripts/deployment/env/00-config.sh ejecuta en mi shell y deja CONT_NAME=oralab-26ai, VOL_NAME, ts(). Con bash 00-config.sh se ejecuta en hija y al terminar se pierden. Por eso cada terminal nueva necesita source, si no salen rutas /script/... sin EVID.
10. Ej. 20261005T175102Z_13-verificacion-final.script.log: fecha UTC ISO8601 compacta ordenable, _13- enlaza con script 13 y Parte N, verificacion-final en kebab-case sin tildes, .script.log indica terminal (vs .spool.log SQL o .png).
11. .gitattributes con *.sh text eol=lf normaliza a LF para todos. Sin él un .sh con CRLF Windows falla en Linux con $'\r': command not found.
12. Elegimos merge commit para conservar ~11 commits uno por Parte (01,02,03...13). Con squash se perdería el paso a paso y no se vería cuándo se verificó cada herramienta.
## Seguridad
13. Cuatro capas: 1) config/.env y backups/ en .gitignore antes de crear nada, 2) config/.env.example versionada solo con change_me, 3) config/.env real local con <mi-ORACLE_PWD> verificado con git check-ignore -v y git status, 4) uso "$ORACLE_PWD" vía set -a; source config/.env. Si saltas la 1, el .env entra en el commit y queda para siempre.
14. No escribo la clave en docker run -e ORACLE_PWD=... porque queda en ~/.bash_history en texto plano. Uso variable, en historial solo sale el nombre.
15. No basta borrar en otro commit, sigue en git log -p. Se da por comprometida: no hacer push, rotarla (nuevo config/.env + recrear oralab-26ai), avisar al docente.
## Oracle y herramientas
16. sqlplus corre con docker exec -i oralab-26ai dentro del contenedor. SPOOL escribiría dentro del contenedor, no en docs/..., y @archivo.sql daría SP2-0310 porque busca dentro. Por eso redirijo desde host < 07-primera-conexion.sql y capturo con tee spool/....
17. WHENEVER SQLERROR EXIT SQL.SQLCODE en V000/V001 hace que sqlplus devuelva error y 08-aplicar-migraciones.sh (con set -euo pipefail) pare. Sin ella seguiría creando tablas sobre un estado a medias.
18. Migración es SQL versionado V000__..., V001__... en database/migrations/ que se aplica en orden. No se editan aplicadas porque compañeros quedarían con esquemas distintos (yo tengo 3,3,2,3,3); se crea V002.
19. En SQL Developer uso Service name FREEPDB1 en localhost:1521, que es la PDB de trabajo OPEN. Con FREE iría a la raíz CDB y con SID fallaría con ORA-12505.
20. SQLcl aporta SET SQLFORMAT ansiconsole, historial, CONNECT -save oralab26-system y SPOOL local en mi equipo. SQLPlus viene en todo servidor Oracle desde 1982 y en el contenedor. A las 3am en servidor solo hay SQLPlus, por eso domino ambas.
## Entorno de trabajo
21. Paso de Git Bash a Ubuntu WSL2 porque Oracle/Docker son Linux. En Git Bash docker run -it daba not a TTY y necesitaba winpty, convertía rutas /opt/... a Windows y rompía Docker, y faltan free/ss/htop, Java pedía clave mal. En Ubuntu todo funciona igual que en servidor.
22. Clono en ~/oracle-database-lab (/home/israel/...) porque es ext4 nativo rápido y conserva permiso de ejecución; en /mnt/c/... cada operación cruza a NTFS, es lento y rompe permisos/LF. Uso bash para scripts porque está en todo servidor y #!/usr/bin/env bash garantiza igual en Ubuntu y macOS; zsh solo es comodidad interactiva en Mac.

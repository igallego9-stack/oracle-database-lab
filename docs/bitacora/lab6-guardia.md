## INC-601 · Bloqueo de la ficha del alumno 101 por una transacción abierta
- Detección: 14:49 UTC · ticket INC-601 · Secretaría (Ana García)
- Impacto: Ana no pudo guardar la ficha del alumno 101; la pantalla se quedó colgada
- Diagnóstico: Sección 1: APP_ACADEMIA SID 213, SERIAL# 60858, PL/SQL lock timer, módulo matriculas, acción cierre-periodo; ANA_GARCIA SID 223, SERIAL# 51128, enq: TX - row lock contention, blocking_session 213. Sección 2: fila 5 de ACA_ESTUDIANTES. Sección 3: TX 196631/719, lmode 6 frente a request 6. Sección 4: 1 bloque de undo y 1 registro de undo. Sección 5: ASH de 14:49:17 a 14:49:21.
- Causa raíz: Ejecutó el UPDATE de la fila 101, no hizo COMMIT ni ROLLBACK y se durmió 900 s, así que retuvo el lock y Ana se quedó esperando.
- Intervención: ALTER SYSTEM KILL SESSION '213,60858' IMMEDIATE; · el ORA-00031 es normal: la sesión queda marcada para morir
- Validación: Fila 101 en ACTIVO; después no quedaban sesiones de APP_ACADEMIA ni de ANA_GARCIA
- Acción preventiva: Evitar transacciones abiertas antes de un SLEEP, vigilar transacciones largas y avisar de bloqueos

## INC-602 · Servicio academia_app parado: ORA-12514
- Detección: 14:58 UTC · ticket INC-602 · equipo de matrículas
- Impacto: Ninguna instancia de la aplicación podía conectar; error ORA-12514
- Diagnóstico: La base estaba abierta y sin bloqueos; sección 6: FREEPDB1 en SI, academia_app en NO; el listener no anunciaba el servicio
- Causa raíz: El servicio existía pero estaba parado; no era la base
- Intervención: DBMS_SERVICE.START_SERVICE('academia_app') + ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE
- Validación: lsnrctl status muestra academia_app READY; 06-app-sigue.sql entra con ROL_APP_ACADEMIA, lee 17600 estudiantes, actualiza 1 fila y da el ORA-00942 esperado en CARGA_HIST
- Acción preventiva: Vigilar que todo servicio existente esté arrancado, incluirlo en la lista de turno y guardar el estado tras cada cambio

## INC-603 · Cuenta APP_ACADEMIA bloqueada por el script de bajas: ORA-28000
- Detección: 14:59 UTC · ticket INC-603 · equipo de matrículas
- Impacto: La aplicación no podía entrar; error ORA-28000
- Diagnóstico: Sección 7: APP_ACADEMIA en LOCKED (no LOCKED(TIMED)), bloqueo del 2026-11-24 14:59, perfil DEFAULT, 10 intentos permitidos; nota del turno de tarde: se ejecutó el script trimestral de bajas
- Causa raíz: El script de bajas no distingue cuentas de personas de cuentas de aplicación
- Intervención: ALTER USER app_academia ACCOUNT UNLOCK;
- Validación: 06-app-sigue.sql vuelve a entrar, lee 17600 estudiantes y actualiza 1 fila
- Acción preventiva: Excluir las cuentas de aplicación del script de bajas y avisar de cambios de estado de cuenta

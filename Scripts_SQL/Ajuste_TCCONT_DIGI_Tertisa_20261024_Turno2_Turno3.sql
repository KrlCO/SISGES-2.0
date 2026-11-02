-- =========================================================================================
-- Script: Ajuste de Contómetros Digitales para Tertisa (GPEBSA02)
-- Fecha: 2026-10-24 | Turnos: 2 y 3
-- Objetivo: Actualizar las lecturas finales de los Turnos 2 y 3 del día 24/10/2026
--           para que continúen la correlatividad del Turno 1 (recién insertado)
--           y cuadren exactamente con las ventas de TCDOCU_COMB, eliminando los
--           valores negativos producidos por la data residual de Petróleo D2.
-- Base de Datos: GPEBSA02 (Servidor 10.15.0.50)
-- =========================================================================================

USE GPEBSA02;
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Obtener los IDs de cabecera de los Turnos 2 y 3 del día 24/10/2026
    DECLARE @ID_T2 INT, @ID_T3 INT;

    SELECT @ID_T2 = CO_CONT_DIGI 
    FROM dbo.TCCONT_DIGI 
    WHERE FE_TURN = '2026-10-24' AND CO_TURN = 2;

    SELECT @ID_T3 = CO_CONT_DIGI 
    FROM dbo.TCCONT_DIGI 
    WHERE FE_TURN = '2026-10-24' AND CO_TURN = 3;

    IF @ID_T2 IS NULL OR @ID_T3 IS NULL
    BEGIN
        RAISERROR('No se encontraron los registros de TCCONT_DIGI para Turno 2 o Turno 3 del 24/10/2026.', 16, 1);
    END;

    PRINT 'ID Turno 2: ' + CAST(@ID_T2 AS VARCHAR(10));
    PRINT 'ID Turno 3: ' + CAST(@ID_T3 AS VARCHAR(10));

    -- 2. Actualizar detalle de Turno 2 (24/10/2026) en TDCONT_DIGI
    -- Lectura Final = Lectura Inicial (Final T1) + Ventas Turno 2 (TCDOCU_COMB):
    -- Lado  9: 560048.6073 + 565.1660 = 560613.7733
    -- Lado 10: 393778.6983 + 684.4360 = 394463.1343
    -- Lado 11: 483917.8116 + 768.5561 = 484686.3677
    -- Lado 12: 662818.4040 + 859.4247 = 663677.8287
    UPDATE dbo.TDCONT_DIGI
    SET IM_LECT = CASE CO_LADO
                    WHEN 9  THEN 560613.7733
                    WHEN 10 THEN 394463.1343
                    WHEN 11 THEN 484686.3677
                    WHEN 12 THEN 663677.8287
                  END
    WHERE CO_CONT_DIGI = @ID_T2;

    -- Actualizar totales de cabecera de Turno 2 en TCCONT_DIGI
    UPDATE dbo.TCCONT_DIGI
    SET IM_GALO = 2877.5828,
        IM_IMPO = 21167.10
    WHERE CO_CONT_DIGI = @ID_T2;

    PRINT 'Turno 2 actualizado correctamente.';

    -- 3. Actualizar detalle de Turno 3 (24/10/2026) en TDCONT_DIGI
    -- Como el Turno 3 no tuvo ventas (0 galones despachados),
    -- su lectura final es idéntica a la final del Turno 2.
    UPDATE dbo.TDCONT_DIGI
    SET IM_LECT = CASE CO_LADO
                    WHEN 9  THEN 560613.7733
                    WHEN 10 THEN 394463.1343
                    WHEN 11 THEN 484686.3677
                    WHEN 12 THEN 663677.8287
                  END
    WHERE CO_CONT_DIGI = @ID_T3;

    -- Actualizar totales de cabecera de Turno 3 en TCCONT_DIGI
    UPDATE dbo.TCCONT_DIGI
    SET IM_GALO = 0.00,
        IM_IMPO = 0.00
    WHERE CO_CONT_DIGI = @ID_T3;

    PRINT 'Turno 3 actualizado correctamente.';

    COMMIT TRANSACTION;
    PRINT 'TRANSACCIÓN COMPLETADA CON ÉXITO. TODOS LOS TURNOS DEL 24/10 ESTÁN CUADRADOS.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR AL ACTUALIZAR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =========================================================================================
-- Verificación de los reportes del día 24/10:
-- =========================================================================================
-- Turno 1: EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261024', 1, '20261023', 3;
-- Turno 2: EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261024', 2, '20261024', 1;
-- Turno 3: EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261024', 3, '20261024', 2;

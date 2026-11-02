-- =========================================================================================
-- Script: Inserción de Contómetros Digitales para Tertisa (GPEBSA02)
-- Fecha Turno: 2026-10-24 | Turno: 1
-- Objetivo: Reconstruir el Turno 1 del 24/10 a partir de las ventas reales en TCDOCU_COMB
--           y la lectura final del Turno anterior (2026-10-23 Turno 3).
-- Base de Datos: GPEBSA02 (Servidor 10.15.0.50)
-- =========================================================================================

USE GPEBSA02;
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Validar que no exista ya el registro de contometros digitales para 24/10 Turno 1
    IF EXISTS (
        SELECT 1 
        FROM dbo.TCCONT_DIGI 
        WHERE CO_EMPR = 1 AND CO_ESTA = 1 AND FE_TURN = '2026-10-24' AND CO_TURN = 1
    )
    BEGIN
        PRINT 'AVISO: Ya existe un registro en TCCONT_DIGI para la fecha 2026-10-24 Turno 1.';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2. Insertar cabecera en TCCONT_DIGI
    -- NOTA: CO_CONT_DIGI es IDENTITY, por lo que SQL Server genera el código automáticamente.
    INSERT INTO dbo.TCCONT_DIGI 
    (
        CO_EMPR, 
        CO_ESTA, 
        CO_TURN, 
        FE_TURN, 
        IM_IMPO, 
        IM_GALO, 
        ST_CONT, 
        CO_USUA_CREA, 
        FE_USUA_CREA
    )
    VALUES 
    (
        1,                       -- CO_EMPR
        1,                       -- CO_ESTA
        1,                       -- CO_TURN (Turno 1)
        '2026-10-24',            -- FE_TURN
        17686.60,                -- IM_IMPO (Total Soles Turno 1 según TCDOCU_COMB)
        2404.3962,               -- IM_GALO (Total Galones Turno 1 según TCDOCU_COMB)
        'N',                     -- ST_CONT
        'PSEVILLA',              -- CO_USUA_CREA
        '2026-10-24 14:00:00'    -- FE_USUA_CREA
    );

    DECLARE @New_CO_CONT_DIGI INT = SCOPE_IDENTITY();
    PRINT 'Cabecera insertada con CO_CONT_DIGI = ' + CAST(@New_CO_CONT_DIGI AS VARCHAR(10));

    -- 3. Insertar detalle en TDCONT_DIGI para los 4 lados de GLP (9, 10, 11, 12)
    -- Lecturas calculadas sumando ventas de TCDOCU_COMB a las lecturas iniciales de 23/10 T3:
    -- Lado  9: 559579.7500 + 468.8573 = 560048.6073
    -- Lado 10: 393110.3125 + 668.3858 = 393778.6983
    -- Lado 11: 483342.1250 + 575.6866 = 483917.8116
    -- Lado 12: 662126.9375 + 691.4665 = 662818.4040

    INSERT INTO dbo.TDCONT_DIGI 
    (
        CO_CONT_DIGI, 
        CO_DCON, 
        CO_PVEN, 
        CO_ISLA, 
        CO_SURT, 
        CO_LADO, 
        CO_MANG, 
        CO_TRAB, 
        CO_PROD, 
        IM_PRE1, 
        IM_PRE2, 
        IM_LECT, 
        IM_GALO, 
        IM_VENT, 
        IM_CALI, 
        ST_DCON
    )
    VALUES 
        (@New_CO_CONT_DIGI, 1, 1, 6, 6,  9, 1, 405, 101070, 7.35, 7.35, 560048.6073, 0.0, 0.0, 0.0, 'N'),
        (@New_CO_CONT_DIGI, 2, 1, 6, 6, 10, 1, 405, 101070, 7.35, 7.35, 393778.6983, 0.0, 0.0, 0.0, 'N'),
        (@New_CO_CONT_DIGI, 3, 1, 6, 6, 11, 1, 405, 101070, 7.35, 7.35, 483917.8116, 0.0, 0.0, 0.0, 'N'),
        (@New_CO_CONT_DIGI, 4, 1, 6, 6, 12, 1, 405, 101070, 7.35, 7.35, 662818.4040, 0.0, 0.0, 0.0, 'N');

    PRINT 'Detalle de 4 lados insertado con éxito en TDCONT_DIGI.';

    COMMIT TRANSACTION;
    PRINT 'TRANSACCIÓN COMPLETADA SATISFACTORIAMENTE.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR AL INSERTAR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =========================================================================================
-- Verificación: Ejecutar el reporte para Turno 1 del 24/10 comparando con Turno 3 del 23/10
-- =========================================================================================
-- EXEC dbo.QSP_TCCONT_DIGI_02 @CO_EMPR=1, @CO_ESTA=1, @FE_TURN='20261024', @CO_TURN=1, @FE_TURN_ANT='20261023', @CO_TURN_ANT=3;

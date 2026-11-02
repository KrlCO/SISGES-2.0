-- =========================================================================================
-- Script 1: SANEAMIENTO INMEDIATO DEL TURNO 1 DE HOY (30/10/2026) EN TERTISA
-- Base de Datos: GPEBSA02 (Servidor 10.15.0.50)
-- Objetivo: Sustituir las lecturas de Petróleo D2 provenientes del DOMS de Pebsa
--           por las lecturas continuas y exactas de GLP para el Turno 1 (ID 23028).
-- =========================================================================================

USE GPEBSA02;
GO

BEGIN TRANSACTION;
BEGIN TRY
    PRINT 'Iniciando corrección de contómetros digitales para 30/10/2026 Turno 1...';

    -- 1. Actualizar lecturas en TDCONT_DIGI para el Turno 1 (ID 23028)
    -- Lecturas base iniciales (29/10 T3): L9=561841.8101, L10=396153.0688, L11=487629.1729, L12=666571.9112
    -- Ventas reales 30/10 T1:           L9=+99.3489,    L10=+209.8189,   L11=+167.5385,   L12=+248.0276
    UPDATE dbo.TDCONT_DIGI
    SET IM_PRE1 = 7.7900,
        IM_LECT = CASE CO_LADO
            WHEN 9  THEN 561941.1590
            WHEN 10 THEN 396362.8877
            WHEN 11 THEN 487796.7114
            WHEN 12 THEN 666819.9388
            ELSE IM_LECT
        END
    WHERE CO_CONT_DIGI = 23028;

    -- 2. Actualizar cabecera TCCONT_DIGI (Total 115 comprobantes: 724.7339 galones | S/ 5,651.30)
    UPDATE dbo.TCCONT_DIGI
    SET IM_GALO = 724.7339,
        IM_IMPO = 5651.30
    WHERE CO_CONT_DIGI = 23028;

    COMMIT TRANSACTION;
    PRINT '>> Corrección aplicada exitosamente en GPEBSA02 para Turno 1.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error al ejecutar corrección: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =========================================================================================
-- VALIDACIÓN DEL REPORTE
-- =========================================================================================
-- 1. Reporte Contómetros vs Comprobantes (debe dar 0.000000 galones de diferencia):
EXEC dbo.QSP_TCCONT_DIGI_04 '2026-10-30', '2026-10-30', 1, 1;

-- 2. Detalle por Manguera (debe mostrar lecturas positivas continuas):
EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261030', 1, '20261029', 3;
GO

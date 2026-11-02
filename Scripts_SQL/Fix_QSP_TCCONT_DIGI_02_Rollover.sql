USE GPEBSA;
GO

/*
========================================================================================
SCRIPT DE CORRECCIÓN: Soporte de Vuelta de Contómetro (Rollover a Cero) en Reporte Digital
Base de datos: GPEBSA (y aplicable a GPEBSA02 si corresponde)
Objeto: dbo.QSP_TCCONT_DIGI_02
Incidencia: Lado 10 (Diesel D2) pasó de 999,659.729 a 155.800 galones (Turno 2 del 28/10/2026).
            Al restar directamente generaba -999,503.929 galones (-S/ 24,337,920.67).
Solución: Si IM_LECF < IM_LECI y la lectura inicial supera 900,000, se suma la capacidad de
          1,000,000 de galones: (1,000,000 - IM_LECI) + IM_LECF.
========================================================================================
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[QSP_TCCONT_DIGI_02]
  @CO_EMPR TINYINT,
  @CO_ESTA TINYINT,
  @FE_TURN VARCHAR(8),
  @CO_TURN TINYINT,
  @FE_TURN_ANT VARCHAR(8),
  @CO_TURN_ANT TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #tmp_lectdigi 
    (
        CO_LADO      TINYINT,
        CO_MANG      TINYINT,
        CO_TRAB      INT,
        CO_PROD      INT,
        DE_PROD_CORT VARCHAR(20),
        IM_PRE1      NUMERIC(9,4),
        IM_LECF      NUMERIC(20,10),
        IM_LECI      NUMERIC(20,10),
        IM_LECT      NUMERIC(20,10),
        IM_VENT      NUMERIC(20,10)
    );

    -- 1. Insertar lecturas finales del turno actual
    INSERT INTO #tmp_lectdigi (CO_LADO, CO_MANG, CO_TRAB, CO_PROD, DE_PROD_CORT, IM_PRE1, IM_LECF)
    SELECT 
        T2.CO_LADO, T2.CO_MANG, T2.CO_TRAB, T2.CO_PROD, T3.DE_PROD_CORT, T2.IM_PRE1, T2.IM_LECT
    FROM TCCONT_DIGI T1 (NOLOCK) 
    INNER JOIN TDCONT_DIGI T2 (NOLOCK) ON T1.CO_CONT_DIGI = T2.CO_CONT_DIGI 
    INNER JOIN TMPROD T3 (NOLOCK) ON T2.CO_PROD = T3.CO_PROD
    WHERE T1.CO_EMPR = @CO_EMPR 
      AND T1.CO_ESTA = @CO_ESTA 
      AND T1.CO_TURN = @CO_TURN 
      AND T1.FE_TURN = @FE_TURN
    ORDER BY T2.CO_LADO, T2.CO_MANG;

    -- 2. Actualizar lecturas iniciales tomadas del turno anterior
    UPDATE T1
    SET T1.IM_LECI = T2.IM_LECT
    FROM #tmp_lectdigi T1
    INNER JOIN (
        SELECT 
            T2.CO_LADO, T2.CO_MANG, T2.CO_TRAB, T2.CO_PROD, T3.DE_PROD_CORT, T2.IM_PRE1, T2.IM_LECT
        FROM TCCONT_DIGI T1 (NOLOCK) 
        INNER JOIN TDCONT_DIGI T2 (NOLOCK) ON T1.CO_CONT_DIGI = T2.CO_CONT_DIGI 
        INNER JOIN TMPROD T3 (NOLOCK) ON T2.CO_PROD = T3.CO_PROD
        WHERE T1.CO_EMPR = 1 
          AND T1.CO_ESTA = 1 
          AND T1.CO_TURN = @CO_TURN_ANT 
          AND T1.FE_TURN = @FE_TURN_ANT
    ) T2 ON T1.CO_LADO = T2.CO_LADO 
        AND T1.CO_MANG = T2.CO_MANG 
        AND T1.CO_PROD = T2.CO_PROD;

    -- 3. Calcular volumen despachado con soporte de vuelta de contómetro (1,000,000 galones)
    UPDATE #tmp_lectdigi 
    SET IM_LECT = CASE 
                    WHEN IM_LECF < IM_LECI AND IM_LECI > 900000 
                    THEN (1000000.0 - IM_LECI) + IM_LECF 
                    ELSE IM_LECF - IM_LECI 
                  END;

    -- 4. Calcular importe total en soles
    UPDATE #tmp_lectdigi 
    SET IM_VENT = IM_PRE1 * IM_LECT;

    -- 5. Devolver resultado ordenado
    SELECT 
        CO_LADO, CO_MANG, CO_TRAB, CO_PROD, DE_PROD_CORT, 
        IM_PRE1, IM_LECI, IM_LECF, IM_LECT, IM_VENT
    FROM #tmp_lectdigi
    ORDER BY CO_LADO, CO_MANG;

    DROP TABLE #tmp_lectdigi;
    RETURN 0;
END;
GO

-- ========================================================================================
-- PRUEBA DE VALIDACIÓN INMEDIATA (Turno 2 del 28/10/2026 frente a Turno 1)
-- ========================================================================================
PRINT '--- Verificando ejecución de QSP_TCCONT_DIGI_02 para Turno 2 (28/10/2026) ---';
EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261028', 2, '20261028', 1;
GO

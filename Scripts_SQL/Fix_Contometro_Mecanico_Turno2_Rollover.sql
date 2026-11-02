USE GPEBSA;
GO

/*
========================================================================================
SOLUCIÓN DEFINITIVA: Desbordamiento / Rollover en Contómetros Mecánicos (Turno 2 - 28/10/2026)
Base de datos: GPEBSA
Servidor: 10.15.0.50

EXPLICACIÓN DEL FENÓMENO:
- En Turno 1, el Lado 10 cerró en 999,659.729.
- En Turno 2, arrancó correctamente en 999,659.729.
- El surtidor físico llegó al límite de 6 dígitos (999,999.999), dio la vuelta a cero
  y finalizó en 155.800 (despachó 340.271 galones antes de la vuelta + 155.800 galones después = 496.071 galones).
- La pantalla y el SP QSP_TMCONT_01 restaban de forma directa (155.800 - 999,659.729 = -999,503.929),
  arrojando un valor negativo y corrompiendo la visualización en pantalla.

ACCIONES DE ESTE SCRIPT:
1. Actualiza el Stored Procedure dbo.QSP_TMCONT_01 con la lógica de desbordamiento (vuelta al millón).
2. Corrige el registro grabado en TDCONT (CO_CONT = 18911, CO_LADO = 10) con los galones e importe positivos reales.
3. Actualiza los totales en cabecera TCCONT (CO_CONT = 18911).
========================================================================================
*/

-- -------------------------------------------------------------------------------------
-- PASO 1: Actualizar QSP_TMCONT_01 con soporte para la vuelta del contómero (Rollover)
-- -------------------------------------------------------------------------------------
PRINT '>>> Actualizando SP dbo.QSP_TMCONT_01...';
GO

ALTER PROCEDURE [dbo].[QSP_TMCONT_01]
       @CO_TURN  TD_TI_001,
       @FE_TURN  TD_VC_008
AS
SET NOCOUNT ON  

/* 
  -Modificación: Soporte para vuelta de contómetros (desbordamiento de 999,999.999 a 0)
  Fecha        : 29/10/2026
*/
SELECT T1.CO_TURN, T1.FE_TURN, 
       T2.CO_LADO, T2.CO_MANG, T4.DE_PROD_CORT 'NO_PROD', 
       T2.IM_PRE1, T2.IM_LECI,
       ISNULL(T2.IM_LECF,0) 'IM_LECF', 
       ISNULL(T2.IM_GALO,0) 'IM_GALO', 
       ISNULL(T2.IM_VENT,0) 'IM_VENT',
       T2.CO_TRAB, ISNULL(T5.NO_TRAB,'') + ' ' + ISNULL(T5.DE_APEL,'')  'NombTra', T3.CO_PROD,
       T1.CO_CONT, T2.CO_DCON, T2.CO_ISLA, T2.CO_SURT, T2.CO_PVEN,
       T1.IM_IMPO 'TOTIMP', T1.IM_GALO 'TOTGAL', IM_CALI, 
       -- Cálculo de Diferencia en Galones con soporte para vuelta de contómero:
       CASE 
           WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 
           THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF
           WHEN T2.IM_LECF > 0 
           THEN T2.IM_LECF - T2.IM_LECI 
           ELSE 0 
       END 'DIFE',
       -- Cálculo de Importe Venta con soporte para vuelta de contómero:
       CASE 
           WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 
           THEN ((1000000.0 - T2.IM_LECI) + T2.IM_LECF) * T2.IM_PRE1
           WHEN T2.IM_LECF > 0 
           THEN (T2.IM_LECF - T2.IM_LECI) * T2.IM_PRE1 
           ELSE 0 
       END 'TOT'
FROM TCCONT T1 (NOLOCK) 
INNER JOIN TDCONT T2 (NOLOCK)
    ON T1.CO_EMPR = T2.CO_EMPR AND T1.CO_ESTA = T2.CO_ESTA AND T1.CO_CONT = T2.CO_CONT 
INNER JOIN TMMANG T3 (NOLOCK)
    ON T2.CO_LADO = T3.CO_LADO AND T2.CO_MANG = T3.CO_MANG 
INNER JOIN TMPROD T4 (NOLOCK)
    ON T2.CO_PROD = T4.CO_PROD 
LEFT JOIN TMTRAB T5 (NOLOCK)
    ON T2.CO_TRAB = T5.CO_TRAB
WHERE T1.CO_TURN = @CO_TURN 
  AND CONVERT(VARCHAR(8), T1.FE_TURN, 112) = @FE_TURN
ORDER BY T2.CO_LADO, T2.CO_MANG;

RETURN 0;
GO

-- -------------------------------------------------------------------------------------
-- PASO 2: Regularizar los valores de TDCONT y TCCONT para el Turno 2 (CO_CONT = 18911)
-- -------------------------------------------------------------------------------------
PRINT '>>> Corrigiendo TDCONT para Turno 2 (CO_CONT = 18911, Lado 10)...';
BEGIN TRANSACTION;

-- Actualizar Lado 10 con los galones e importe positivos reales:
UPDATE TDCONT
SET IM_GALO = 496.071,
    IM_VENT = ROUND(496.071 * IM_PRE1, 2) -- 496.071 * 24.35 = 12079.33
WHERE CO_CONT = 18911 
  AND CO_LADO = 10;

-- Actualizar totales de la cabecera TCCONT
UPDATE TCCONT
SET IM_GALO = (SELECT SUM(IM_GALO) FROM TDCONT WHERE CO_CONT = 18911),
    IM_IMPO = (SELECT SUM(IM_VENT) FROM TDCONT WHERE CO_CONT = 18911)
WHERE CO_CONT = 18911;

COMMIT TRANSACTION;
PRINT '>>> TDCONT y TCCONT actualizados correctamente.';
GO

-- -------------------------------------------------------------------------------------
-- VALIDACIÓN FINAL: Verificar datos actualizados
-- -------------------------------------------------------------------------------------
PRINT '>>> Validación de Lado 10 en TDCONT:';
SELECT CO_CONT, CO_LADO, CO_MANG, IM_PRE1, IM_LECI, IM_LECF, IM_GALO, IM_VENT 
FROM TDCONT 
WHERE CO_CONT = 18911 AND CO_LADO = 10;

PRINT '>>> Validación de Totales en TCCONT:';
SELECT CO_CONT, CO_TURN, FE_TURN, IM_GALO AS TOTAL_GALONES, IM_IMPO AS TOTAL_SOLES 
FROM TCCONT 
WHERE CO_CONT = 18911;
GO

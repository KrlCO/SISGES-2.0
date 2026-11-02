USE GPEBSA02;
GO

/*
========================================================================================
SCRIPT DE SOLUCIÓN AL PROBLEMA INICIAL: TERTISA REFLEJABA PETRÓLEO (D2) EN LUGAR DE GLP
Base de datos: GPEBSA02 (Tertisa Combustibles)
Fecha: 29/10/2026

PROBLEMA INICIAL REPORTADO:
- En la isla de GLP de Tertisa (Lados 9 a 12), el reporte y las tablas de contómetros
  digitales (TCCONT_DIGI / TDCONT_DIGI) registraban producto "D2" (Petróleo / 101050)
  a precio S/ 12.39 en lugar de "GLP" (101070) con su precio real (S/ 7.35 o 7.79).

CAUSA:
- El ejecutable en isla consulta el servicio DOMS (10.15.0.50:8888), el cual pertenece
  a Grifos Pebsa (líquidos), donde los lados 9 a 12 corresponden a Diesel D2 (GradeId 04).
- Al recibir GradeId 04, el sistema asignaba código 101050 (D2) y precio 12.39.

ESTE SCRIPT APLICA 3 CORRECCIONES:
1. Actualiza SP_TCCONT_DIGI_I01 para que SIEMPRE tome el producto real de la manguera
   configurado en TMMANG (101070 - GLP) y el precio de GLP, evitando que vuelva a entrar D2.
2. Actualiza QSP_TCCONT_DIGI_02 en GPEBSA02 con soporte de vuelta de contómetro.
3. Regulariza los registros históricos ya grabados en TDCONT_DIGI (desde 23009)
   cambiando el producto a 101070 (GLP) y corrigiendo sus precios.
========================================================================================
*/

-- --------------------------------------------------------------------------------------
-- PARTE 1: CORREGIR SP_TCCONT_DIGI_I01 (Para que en futuros turnos SIEMPRE grabe GLP)
-- --------------------------------------------------------------------------------------
PRINT '--- 1. Actualizando SP_TCCONT_DIGI_I01 en GPEBSA02 ---';
GO

ALTER PROC [dbo].[SP_TCCONT_DIGI_I01]
	@DATA VARCHAR(MAX)
AS BEGIN
	BEGIN TRAN SP_TURNO
		SET NOCOUNT ON
		TRUNCATE TABLE temp.temp_lados
		EXEC(@DATA)
		DECLARE
		@VNCO_CONT_DIGI INT,
		@VSCO_USUA_CREA VARCHAR(8),
		@VDFE_TURN DATE,
		@VNCO_TURN INT
		SELECT @VNCO_TURN=CO_TURN, @VDFE_TURN=FE_TURN FROM TTTURN
		WHERE ST_TURN='ACT'
		SELECT @VSCO_USUA_CREA=CO_USUA_MODI FROM TTPARA_FILT
		WHERE COPARA_FILT=21
		IF NOT EXISTS(SELECT * FROM TCCONT_DIGI WHERE FE_TURN=@VDFE_TURN AND CO_TURN=@VNCO_TURN)
		BEGIN
			INSERT INTO TCCONT_DIGI VALUES
			(1, 1, @VNCO_TURN, @VDFE_TURN, 0, 0, 'N', @VSCO_USUA_CREA, GETDATE(), NULL, NULL)
			SELECT @VNCO_CONT_DIGI=SCOPE_IDENTITY()
			SET NOCOUNT OFF
			INSERT INTO TDCONT_DIGI
			SELECT @VNCO_CONT_DIGI, T1.REGISTROS, T4.CO_PVEN, T3.CO_ISLA, T4.CO_SURT, T1.LADO, T1.MANGUERA, T2.CO_TRAB, 
                   T3.CO_PROD, T5.IM_VENT, T5.IM_PPUB_SIGV, T1.VOLUMEN, 0, T1.MONEY, 0, 'N'
			FROM temp.temp_lados T1 WITH(NOLOCK)
			INNER JOIN TTTRABA_LADO T2 WITH(NOLOCK) ON T1.LADO=T2.CO_LADO
			INNER JOIN TMMANG T3 WITH(NOLOCK) ON T1.LADO=T3.CO_LADO AND T1.MANGUERA=T3.CO_MANG
			INNER JOIN TMLADO T4 WITH(NOLOCK) ON T1.LADO=T4.CO_LADO
			INNER JOIN TMPROD T5 WITH(NOLOCK) ON T3.CO_PROD=T5.CO_PROD -- Asegura precio y código de GLP
		END ELSE
		BEGIN
			SELECT @VNCO_CONT_DIGI=CO_CONT_DIGI FROM TCCONT_DIGI WHERE FE_TURN=@VDFE_TURN AND CO_TURN=@VNCO_TURN
			SET NOCOUNT OFF
			INSERT INTO TDCONT_DIGI
			SELECT @VNCO_CONT_DIGI, T1.REGISTROS, T4.CO_PVEN, T3.CO_ISLA, T4.CO_SURT, T1.LADO, T1.MANGUERA, T2.CO_TRAB, 
                   T3.CO_PROD, T5.IM_VENT, T5.IM_PPUB_SIGV, T1.VOLUMEN, 0, T1.MONEY, 0, 'N'
			FROM temp.temp_lados T1 WITH(NOLOCK)
			INNER JOIN TTTRABA_LADO T2 WITH(NOLOCK) ON T1.LADO=T2.CO_LADO
			INNER JOIN TMMANG T3 WITH(NOLOCK) ON T1.LADO=T3.CO_LADO AND T1.MANGUERA=T3.CO_MANG
			INNER JOIN TMLADO T4 WITH(NOLOCK) ON T1.LADO=T4.CO_LADO
			INNER JOIN TMPROD T5 WITH(NOLOCK) ON T3.CO_PROD=T5.CO_PROD -- Asegura precio y código de GLP
		END
	COMMIT TRAN SP_TURNO
END
GO

-- --------------------------------------------------------------------------------------
-- PARTE 2: CORREGIR QSP_TCCONT_DIGI_02 EN GPEBSA02 (Con soporte de vuelta de contómetro)
-- --------------------------------------------------------------------------------------
PRINT '--- 2. Actualizando QSP_TCCONT_DIGI_02 en GPEBSA02 ---';
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

    -- Soporte para rollover / vuelta a cero
    UPDATE #tmp_lectdigi 
    SET IM_LECT = CASE 
                    WHEN IM_LECF < IM_LECI AND IM_LECI > 900000 
                    THEN (1000000.0 - IM_LECI) + IM_LECF 
                    ELSE IM_LECF - IM_LECI 
                  END;

    UPDATE #tmp_lectdigi 
    SET IM_VENT = IM_PRE1 * IM_LECT;

    SELECT 
        CO_LADO, CO_MANG, CO_TRAB, CO_PROD, DE_PROD_CORT, 
        IM_PRE1, IM_LECI, IM_LECF, IM_LECT, IM_VENT
    FROM #tmp_lectdigi
    ORDER BY CO_LADO, CO_MANG;

    DROP TABLE #tmp_lectdigi;
    RETURN 0;
END;
GO

-- --------------------------------------------------------------------------------------
-- PARTE 3: REGULARIZAR HISTÓRICO DE TDCONT_DIGI EN GPEBSA02 (Turnos del 24/10 en adelante)
-- --------------------------------------------------------------------------------------
PRINT '--- 3. Regularizando registros históricos de TDCONT_DIGI a GLP (101070) ---';
GO

BEGIN TRANSACTION;

UPDATE d
SET 
    d.CO_PROD = 101070, -- Cambia de D2 (101050) a GLP (101070)
    d.IM_PRE1 = CASE 
                    -- Turnos anteriores o iguales al Turno 1 del 25/10 tenían precio S/ 7.35
                    WHEN c.FE_TURN < '2026-10-25' OR (c.FE_TURN = '2026-10-25' AND c.CO_TURN = 1) THEN 7.35
                    -- A partir del Turno 2 del 25/10 el precio subió a S/ 7.79
                    ELSE 7.79 
                END
FROM TDCONT_DIGI d
INNER JOIN TCCONT_DIGI c ON d.CO_CONT_DIGI = c.CO_CONT_DIGI
WHERE d.CO_CONT_DIGI >= 23009 -- Desde el inicio del incidente el 24/10
  AND d.CO_PROD = 101050;     -- Solo los que quedaron como D2

COMMIT TRANSACTION;
PRINT '>>> HISTÓRICO DE TERTISA CORREGIDO CON ÉXITO A GLP (101070). <<<';
GO

-- --------------------------------------------------------------------------------------
-- PARTE 4: VALIDACIÓN DEL REPORTE DEL TURNO 2 (24/10/2026) QUE SALÍA CON D2
-- --------------------------------------------------------------------------------------
PRINT '--- Validando reporte de la imagen (Turno 2 del 24/10/2026 en GPEBSA02) ---';
EXEC dbo.QSP_TCCONT_DIGI_02 1, 1, '20261024', 2, '20261024', 1;
GO

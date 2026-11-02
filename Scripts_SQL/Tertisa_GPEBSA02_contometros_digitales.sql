/*=====================================================================================
  Tertisa Combustibles - Servidor 10.15.0.50 - Base GPEBSA02
  Crea los objetos que usa el Cierre de Turno (frmCierreTurno.frm) y que faltan en GPEBSA02:

    1. temp.temp_lados          (tabla de paso: Sisges hace INSERT INTO temp.temp_lados VALUES ...)
    2. dbo.SP_TCCONT_DIGI_I01   (MstTurno.InsertaContometro) -> causa de "Error al guardar contometros"
    3. dbo.USP_TTTURN_02        (MstTurno.CambTurno) -> cierra el turno ACT e inserta el siguiente.
                                 Sin el, aunque se graben los contometros, el turno no cambia.

  Definiciones copiadas tal cual de GPEBSA (Pebsa), mismo servidor:
    - temp.temp_lados creada el 01/07/2022, sin PK ni indices (heap)
    - SP_TCCONT_DIGI_I01 modificado el 29/09/2022, EXECUTE concedido a public
    - USP_TTTURN_02 modificado el 06/07/2022, EXECUTE concedido a public
      (usa los tipos TD_DT_001 y TD_TI_001, que ya existen en GPEBSA02)

  El script es re-ejecutable: no toca nada si los objetos ya existen.
  NO cierra ni modifica el turno 2 del 24/10/2026 que quedo abierto: eso se revisa aparte.

  Preparado: 2026-10-25 - SIN EJECUTAR
=====================================================================================*/

USE GPEBSA02;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*-------------------------------------------------------------------------------------
  0. Verificaciones previas (solo lectura). Deben salir: esquema temp = SI, objetos = NO
-------------------------------------------------------------------------------------*/
SELECT
    DB_NAME()                                                                   AS base,
    CASE WHEN SCHEMA_ID('temp') IS NULL THEN 'NO' ELSE 'SI' END                 AS esquema_temp,
    CASE WHEN OBJECT_ID('temp.temp_lados', 'U') IS NULL THEN 'NO' ELSE 'SI' END AS tabla_temp_lados,
    CASE WHEN OBJECT_ID('dbo.SP_TCCONT_DIGI_I01', 'P') IS NULL THEN 'NO' ELSE 'SI' END AS sp_tccont_digi_i01,
    CASE WHEN OBJECT_ID('dbo.USP_TTTURN_02', 'P') IS NULL THEN 'NO' ELSE 'SI' END AS usp_ttturn_02;
GO

-- El esquema temp ya existe en GPEBSA02 (dueño dba01); se crea solo por si acaso
IF SCHEMA_ID('temp') IS NULL
    EXEC('CREATE SCHEMA temp AUTHORIZATION dba01');
GO

/*-------------------------------------------------------------------------------------
  1. Tabla temp.temp_lados (igual que GPEBSA.temp.temp_lados)
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('temp.temp_lados', 'U') IS NULL
BEGIN
    CREATE TABLE temp.temp_lados
    (
        REGISTROS INT           NOT NULL,
        LADO      INT           NOT NULL,
        MANGUERA  INT           NOT NULL,
        PRODUCTO  VARCHAR(6)    COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        VOLUMEN   NUMERIC(16,4) NOT NULL,
        MONEY     NUMERIC(16,4) NOT NULL
    );
    PRINT 'Creada la tabla temp.temp_lados';
END
ELSE
    PRINT 'temp.temp_lados ya existia: no se modifico';
GO

/*-------------------------------------------------------------------------------------
  2. Procedimiento dbo.SP_TCCONT_DIGI_I01 (texto identico al de GPEBSA)
     CREATE PROCEDURE debe ser la primera sentencia del lote: si ya existe, se omite
     con un lote dinamico.
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.SP_TCCONT_DIGI_I01', 'P') IS NOT NULL
BEGIN
    PRINT 'dbo.SP_TCCONT_DIGI_I01 ya existia: no se modifico';
    SET NOEXEC ON;   -- salta el CREATE PROCEDURE del lote siguiente
END
GO

CREATE PROC [dbo].[SP_TCCONT_DIGI_I01]
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
			SELECT @VNCO_CONT_DIGI, T1.REGISTROS, T4.CO_PVEN, T3.CO_ISLA, T4.CO_SURT, T1.LADO, T1.MANGUERA, T2.CO_TRAB, T1.PRODUCTO, T5.IM_VENT, T5.IM_PPUB_SIGV, T1.VOLUMEN, 0, T1.MONEY, 0, 'N'
			FROM temp.temp_lados T1 WITH(NOLOCK)
			INNER JOIN TTTRABA_LADO T2 WITH(NOLOCK) ON T1.LADO=T2.CO_LADO
			INNER JOIN TMMANG T3 WITH(NOLOCK) ON T1.LADO=T3.CO_LADO AND T1.MANGUERA=T3.CO_MANG
			INNER JOIN TMLADO T4 WITH(NOLOCK) ON T1.LADO=T4.CO_LADO
			INNER JOIN TMPROD T5 WITH(NOLOCK) ON T1.PRODUCTO=T5.CO_PROD
		END ELSE
		BEGIN
			SELECT @VNCO_CONT_DIGI=CO_CONT_DIGI FROM TCCONT_DIGI WHERE FE_TURN=@VDFE_TURN AND CO_TURN=@VNCO_TURN
			SET NOCOUNT OFF
			INSERT INTO TDCONT_DIGI
			SELECT @VNCO_CONT_DIGI, T1.REGISTROS, T4.CO_PVEN, T3.CO_ISLA, T4.CO_SURT, T1.LADO, T1.MANGUERA, T2.CO_TRAB, T1.PRODUCTO, T5.IM_VENT, T5.IM_PPUB_SIGV, T1.VOLUMEN, 0, T1.MONEY, 0, 'N'
			FROM temp.temp_lados T1 WITH(NOLOCK)
			INNER JOIN TTTRABA_LADO T2 WITH(NOLOCK) ON T1.LADO=T2.CO_LADO
			INNER JOIN TMMANG T3 WITH(NOLOCK) ON T1.LADO=T3.CO_LADO AND T1.MANGUERA=T3.CO_MANG
			INNER JOIN TMLADO T4 WITH(NOLOCK) ON T1.LADO=T4.CO_LADO
			INNER JOIN TMPROD T5 WITH(NOLOCK) ON T1.PRODUCTO=T5.CO_PROD
		END
	COMMIT TRAN SP_TURNO
END
GO

SET NOEXEC OFF;
GO

-- Mismo permiso que en GPEBSA
GRANT EXECUTE ON dbo.SP_TCCONT_DIGI_I01 TO public;
GO

/*-------------------------------------------------------------------------------------
  3. Procedimiento dbo.USP_TTTURN_02 (texto identico al de GPEBSA)
     Cierra el turno indicado (CER, con el usuario del parametro 21) e inserta el siguiente
     como ACT: 1 -> 2, 2 -> 3, 3 -> turno 1 del dia siguiente.
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.USP_TTTURN_02', 'P') IS NOT NULL
BEGIN
    PRINT 'dbo.USP_TTTURN_02 ya existia: no se modifico';
    SET NOEXEC ON;   -- salta el CREATE PROCEDURE del lote siguiente
END
GO

CREATE PROCEDURE USP_TTTURN_02
	@FE_TURNAN TD_DT_001,
	@CO_TURNAN TD_TI_001
AS BEGIN
	UPDATE TTTURN SET
	ST_TURN = 'CER',
	CO_USUA_CREA = (SELECT CO_USUA_MODI FROM TTPARA_FILT WHERE COPARA_FILT = 21),
	FE_USUA_CREA = GETDATE()
	WHERE FE_TURN = @FE_TURNAN
	AND CO_TURN = @CO_TURNAN

	DECLARE @CO_TURNNU TD_TI_001
	DECLARE @FE_TURNNU TD_DT_001

	SELECT @CO_TURNNU=CASE
	WHEN @CO_TURNAN=1 THEN 2
	WHEN @CO_TURNAN=2 THEN 3
	WHEN @CO_TURNAN=3 THEN 1
	END,
	@FE_TURNNU=CASE
	WHEN @CO_TURNAN=1 THEN @FE_TURNAN
	WHEN @CO_TURNAN=2 THEN @FE_TURNAN
	WHEN @CO_TURNAN=3 THEN DATEADD(DD, 1, CONVERT(DATE, @FE_TURNAN))
	END

	INSERT INTO TTTURN (FE_TURN, CO_TURN, ST_TURN)
	SELECT @FE_TURNNU, @CO_TURNNU, 'ACT'
END
GO

SET NOEXEC OFF;
GO

-- Mismo permiso que en GPEBSA
GRANT EXECUTE ON dbo.USP_TTTURN_02 TO public;
GO

/*-------------------------------------------------------------------------------------
  4. Verificacion final (solo lectura). Deben salir SI, la estructura de la tabla y
     UN SOLO turno ACT (este script no cambia el turno: sigue siendo el 24/10 turno 2
     hasta que se cierre desde la isla).
-------------------------------------------------------------------------------------*/
SELECT
    CASE WHEN OBJECT_ID('temp.temp_lados', 'U') IS NULL THEN 'NO' ELSE 'SI' END        AS tabla_temp_lados,
    CASE WHEN OBJECT_ID('dbo.SP_TCCONT_DIGI_I01', 'P') IS NULL THEN 'NO' ELSE 'SI' END AS sp_tccont_digi_i01,
    CASE WHEN OBJECT_ID('dbo.USP_TTTURN_02', 'P') IS NULL THEN 'NO' ELSE 'SI' END      AS usp_ttturn_02;

SELECT FE_TURN, CO_TURN, ST_TURN FROM TTTURN WHERE ST_TURN = 'ACT';

SELECT c.column_id, c.name, TYPE_NAME(c.user_type_id) AS tipo, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('temp.temp_lados')
ORDER BY c.column_id;
GO

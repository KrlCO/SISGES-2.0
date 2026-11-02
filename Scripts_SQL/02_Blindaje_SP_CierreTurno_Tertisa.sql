-- =========================================================================================
-- Script 2: BLINDAJE DEFINITIVO DE CIERRE DE TURNO EN TERTISA (GPEBSA02)
-- Base de Datos: GPEBSA02 (Servidor 10.15.0.50)
-- Procedimiento: dbo.SP_TCCONT_DIGI_I01
-- Objetivo: Evitar de manera definitiva que el POS VILISLA29 inserte lecturas de Diesel D2
--           del DOMS de Pebsa al cerrar turnos en Tertisa (GLP).
-- Mecanismo: Calcula automáticamente la lectura continua de GLP (Lectura Anterior + Ventas del Turno)
--            garantizando que cada cierre futuro quede 100% cuadrado sin errores.
-- =========================================================================================

USE GPEBSA02;
GO

CREATE OR ALTER PROC [dbo].[SP_TCCONT_DIGI_I01]
    @DATA VARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- un error dentro de EXEC(@DATA) no deja la transaccion a medias
    BEGIN TRAN SP_TURNO;
    BEGIN TRY
        -- Truncar y ejecutar datos enviados por el POS para mantener compatibilidad con VB6
        TRUNCATE TABLE temp.temp_lados;
        EXEC(@DATA);

        DECLARE
            @VNCO_CONT_DIGI INT,
            @VSCO_USUA_CREA VARCHAR(8),
            @VDFE_TURN      DATE,
            @VNCO_TURN      INT,
            @VTOT_GALO      NUMERIC(19,4),
            @VTOT_IMPO      NUMERIC(19,2);

        -- Obtener el turno que se está cerrando. frmCierreTurno llama a este SP ANTES de
        -- USP_TTTURN_02, así que siempre debe haber un turno ACT. Si no lo hay, se aborta
        -- (antes caía al último CER y lo borraba/reconstruía en silencio).
        SELECT TOP 1 @VNCO_TURN = CO_TURN, @VDFE_TURN = FE_TURN
        FROM dbo.TTTURN
        WHERE ST_TURN = 'ACT'
        ORDER BY FE_TURN DESC, CO_TURN DESC;

        IF @VNCO_TURN IS NULL
            RAISERROR('SP_TCCONT_DIGI_I01: no hay turno ACT en TTTURN; no se graban contometros.', 16, 1);

        SELECT @VSCO_USUA_CREA = CO_USUA_MODI 
        FROM dbo.TTPARA_FILT 
        WHERE COPARA_FILT = 21;

        -- Calcular los totales reales vendidos en el turno desde TCDOCU_COMB
        SELECT 
            @VTOT_GALO = ISNULL(SUM(NU_GALN), 0),
            @VTOT_IMPO = ISNULL(SUM(IM_TOTA), 0)
        FROM dbo.TCDOCU_COMB
        WHERE FE_TURN = @VDFE_TURN AND CO_TURN = @VNCO_TURN
          AND ST_DVEN <> 'A';  -- excluir anulados

        -- Crear o actualizar cabecera TCCONT_DIGI con los valores reales del turno
        IF NOT EXISTS (SELECT 1 FROM dbo.TCCONT_DIGI WHERE FE_TURN = @VDFE_TURN AND CO_TURN = @VNCO_TURN)
        BEGIN
            INSERT INTO dbo.TCCONT_DIGI (
                CO_EMPR, CO_ESTA, CO_TURN, FE_TURN, IM_IMPO, IM_GALO, ST_CONT, CO_USUA_CREA, FE_USUA_CREA, CO_USUA_MODI, FE_USUA_MODI
            ) VALUES (
                1, 1, @VNCO_TURN, @VDFE_TURN, @VTOT_IMPO, @VTOT_GALO, 'N', @VSCO_USUA_CREA, GETDATE(), NULL, NULL
            );
            SELECT @VNCO_CONT_DIGI = SCOPE_IDENTITY();
        END 
        ELSE
        BEGIN
            SELECT @VNCO_CONT_DIGI = CO_CONT_DIGI 
            FROM dbo.TCCONT_DIGI 
            WHERE FE_TURN = @VDFE_TURN AND CO_TURN = @VNCO_TURN;

            UPDATE dbo.TCCONT_DIGI 
            SET IM_IMPO = @VTOT_IMPO, 
                IM_GALO = @VTOT_GALO
            WHERE CO_CONT_DIGI = @VNCO_CONT_DIGI;
        END

        -- Limpiar registros existentes de este turno en TDCONT_DIGI para evitar duplicados
        DELETE FROM dbo.TDCONT_DIGI WHERE CO_CONT_DIGI = @VNCO_CONT_DIGI;

        -- Reconstruir contometros continuos de GLP: Lectura anterior + Ventas del turno
        ;WITH LecturasPrevias AS (
            SELECT 
                d.CO_LADO, 
                d.IM_LECT as LECTURA_ANT,
                ROW_NUMBER() OVER(PARTITION BY d.CO_LADO ORDER BY c.FE_TURN DESC, c.CO_TURN DESC) as rn
            FROM dbo.TDCONT_DIGI d
            JOIN dbo.TCCONT_DIGI c ON d.CO_CONT_DIGI = c.CO_CONT_DIGI
            WHERE (c.FE_TURN < @VDFE_TURN OR (c.FE_TURN = @VDFE_TURN AND c.CO_TURN < @VNCO_TURN))
              AND d.CO_LADO IN (9, 10, 11, 12)
        ),
        VentasTurno AS (
            SELECT 
                NU_LADO,
                ISNULL(SUM(NU_GALN), 0) as GALONES_TURNO,
                ISNULL(SUM(IM_TOTA), 0) as SOLES_TURNO
            FROM dbo.TCDOCU_COMB
            WHERE FE_TURN = @VDFE_TURN AND CO_TURN = @VNCO_TURN
              AND ST_DVEN <> 'A'  -- excluir anulados
            GROUP BY NU_LADO
        )
        INSERT INTO dbo.TDCONT_DIGI (
            CO_CONT_DIGI, CO_DCON, CO_PVEN, CO_ISLA, CO_SURT, CO_LADO, CO_MANG, CO_TRAB,
            CO_PROD, IM_PRE1, IM_PRE2, IM_LECT, IM_GALO, IM_VENT, IM_CALI, ST_DCON
        )
        SELECT 
            @VNCO_CONT_DIGI,
            ROW_NUMBER() OVER(ORDER BY m.CO_LADO),
            l.CO_PVEN,
            m.CO_ISLA,
            l.CO_SURT,
            m.CO_LADO,
            m.CO_MANG,
            ISNULL(tl.CO_TRAB, 0),
            m.CO_PROD,
            p.IM_VENT,
            p.IM_PPUB_SIGV,
            ISNULL(lp.LECTURA_ANT, 0) + ISNULL(vt.GALONES_TURNO, 0), -- Lectura matemática continua
            ISNULL(vt.GALONES_TURNO, 0),
            ISNULL(vt.SOLES_TURNO, 0),
            0,
            'N'
        FROM dbo.TMMANG m WITH(NOLOCK)
        INNER JOIN dbo.TMLADO l WITH(NOLOCK) ON m.CO_LADO = l.CO_LADO
        INNER JOIN dbo.TMPROD p WITH(NOLOCK) ON m.CO_PROD = p.CO_PROD
        LEFT JOIN dbo.TTTRABA_LADO tl WITH(NOLOCK) ON m.CO_LADO = tl.CO_LADO
        LEFT JOIN LecturasPrevias lp ON m.CO_LADO = lp.CO_LADO AND lp.rn = 1
        LEFT JOIN VentasTurno vt ON m.CO_LADO = vt.NU_LADO
        WHERE m.CO_LADO IN (9, 10, 11, 12)
        ORDER BY m.CO_LADO, m.CO_MANG;

        COMMIT TRAN SP_TURNO;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN SP_TURNO;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO

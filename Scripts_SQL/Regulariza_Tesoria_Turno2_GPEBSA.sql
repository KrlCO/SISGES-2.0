USE GPEBSA;
GO

/*
========================================================================================
SCRIPT DE REGULARIZACIÓN: Inserción de Turno 2 (28/10/2026) en Contómetros Mecánicos (Tesorería)
Base de datos: GPEBSA
Tablas afectadas: dbo.TCCONT, dbo.TDCONT
Finalidad: Desbloquear el ingreso de ventas en Tesorería.
           Al registrar el Turno 2 con la lectura final del Lado 10 en 155.80,
           el Turno 3 iniciará automáticamente en 155.80 sin desbordar dígitos.
Valores registrados en Lado 10:
  - Lectura Inicial: 999659.73
  - Lectura Final:   155.80
  - Galones:         496.07
  - Importe Soles:   12,079.33 (cuadrado con las 40 ventas del turno)
========================================================================================
*/

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Validar que no exista ya el Turno 2 para esa fecha
    IF EXISTS (SELECT 1 FROM TCCONT WHERE FE_TURN = '2026-10-28' AND CO_TURN = 2)
    BEGIN
        PRINT 'El Turno 2 del 28/10/2026 ya se encuentra registrado en TCCONT.';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2. Obtener el siguiente correlativo para TCCONT
    DECLARE @NuevoCO_CONT INT;
    SELECT @NuevoCO_CONT = ISNULL(MAX(CO_CONT), 0) + 1 FROM TCCONT;

    PRINT 'Insertando cabecera en TCCONT con correlativo: ' + CAST(@NuevoCO_CONT AS VARCHAR);

    INSERT INTO TCCONT (
        CO_EMPR, CO_ESTA, CO_CONT, CO_TURN, FE_TURN, 
        IM_IMPO, DE_TLEC, IM_GALO, ST_CONT, CO_USUA_CREA, FE_USUA_CREA
    )
    VALUES (
        1, 1, @NuevoCO_CONT, 2, '2026-10-28', 
        0.00, 'M', 0.00, 'N', 'SISTEMAS', GETDATE()
    );

    -- 3. Insertar los detalles en TDCONT tomando las lecturas iniciales de Turno 1 (18910)
    --    y las lecturas finales del cierre digital (21632)
    PRINT 'Insertando detalles de surtidores en TDCONT...';

    INSERT INTO TDCONT (
        CO_EMPR, CO_ESTA, CO_CONT, CO_DCON, CO_PVEN, CO_ISLA, CO_SURT, CO_LADO, CO_MANG,
        CO_TRAB, CO_PROD, IM_PRE1, IM_PRE2, IM_LECI, IM_LECF, IM_VENT, IM_GALO, ST_DCON, IM_CALI
    )
    SELECT 
        1 AS CO_EMPR,
        1 AS CO_ESTA,
        @NuevoCO_CONT AS CO_CONT,
        t1.CO_DCON,
        t1.CO_PVEN,
        t1.CO_ISLA,
        t1.CO_SURT,
        t1.CO_LADO,
        t1.CO_MANG,
        t1.CO_TRAB,
        t1.CO_PROD,
        t1.IM_PRE1,
        0 AS IM_PRE2,
        t1.IM_LECF AS IM_LECI, -- La lectura final de T1 es la inicial de T2
        t2.IM_LECT AS IM_LECF, -- La lectura del cierre digital de T2
        -- Cálculo de Venta en Soles:
        t1.IM_PRE1 * CASE 
            WHEN t2.IM_LECT < t1.IM_LECF AND t1.IM_LECF > 900000 
            THEN (1000000.0 - t1.IM_LECF) + t2.IM_LECT
            ELSE t2.IM_LECT - t1.IM_LECF 
        END AS IM_VENT,
        -- Cálculo de Galones con soporte de vuelta de contómetro en Lado 10:
        CASE 
            WHEN t2.IM_LECT < t1.IM_LECF AND t1.IM_LECF > 900000 
            THEN (1000000.0 - t1.IM_LECF) + t2.IM_LECT
            ELSE t2.IM_LECT - t1.IM_LECF 
        END AS IM_GALO,
        'N' AS ST_DCON,
        0 AS IM_CALI
    FROM TDCONT t1
    INNER JOIN TDCONT_DIGI t2 
        ON t1.CO_LADO = t2.CO_LADO AND t1.CO_MANG = t2.CO_MANG
    WHERE t1.CO_CONT = 18910          -- Turno 1 del 28/10
      AND t2.CO_CONT_DIGI = 21632;    -- Cierre digital del Turno 2

    PRINT 'Validando datos insertados para Lado 10...';
    SELECT 
        CO_CONT, CO_LADO, CO_MANG, CO_PROD, IM_PRE1, 
        IM_LECI, IM_LECF, IM_GALO, IM_VENT
    FROM TDCONT
    WHERE CO_CONT = @NuevoCO_CONT AND CO_LADO = 10;

    COMMIT TRANSACTION;
    PRINT '>>> REGULARIZACIÓN COMPLETADA CON ÉXITO. Turno 2 registrado en TCCONT / TDCONT. <<<';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error ocurrido: ' + ERROR_MESSAGE();
END CATCH;
GO

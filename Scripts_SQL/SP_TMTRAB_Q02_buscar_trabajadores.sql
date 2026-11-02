/*=====================================================================================
  dbo.SP_TMTRAB_Q02 - Búsqueda de trabajadores / usuarios (SISGES V2.0, Tablas / Trabajadores)
  Reemplaza la consulta en línea de TrabajadorRepository.BuscarAsync.

  - Ejecutar en las 6 bases (DBGRIFO, DBGRIFO_SOYUZ, SGCAHUACHE, GPEBSA, GPEBSA02, SISGES_CICA):
    cada grifo tiene su propia TMTRAB y la web llama al SP del grifo activo.
  - Compatible con SQL Server 2008 R2 (Soyuz y SISGES CICA): no usa CREATE OR ALTER (2016 SP1+).
    Se crea un SP vacío si no existe y luego se hace ALTER: así se puede volver a ejecutar
    y no se pierden los permisos.
  - Solo lectura (NOLOCK). Nombre siguiendo el patrón del sistema: SP_<tabla>_Qnn (ya existe SP_TMTRAB_Q01).

  Preparado: 2026-10-29 - SIN EJECUTAR
=====================================================================================*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.SP_TMTRAB_Q02', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.SP_TMTRAB_Q02 AS RETURN 0');
GO

ALTER PROCEDURE dbo.SP_TMTRAB_Q02
       @ISDE_BUSQ  TD_VC_050 = NULL,     -- apellidos, nombres, usuario o DNI (vacío = todos)
       @ISST_INAC  TD_VC_001 = 'N'       -- 'S' = incluir inactivos
AS
SET NOCOUNT ON;

-- Un NULL desde la aplicación no debe dejar la búsqueda sin resultados
SELECT @ISDE_BUSQ = LTRIM(RTRIM(ISNULL(@ISDE_BUSQ, ''))),
       @ISST_INAC = ISNULL(@ISST_INAC, 'N');

SELECT T.CO_TRAB,
       LTRIM(RTRIM(ISNULL(T.DE_APEL, '') + ' ' + ISNULL(T.NO_TRAB, ''))) AS APE_NOM,
       CASE WHEN T.ST_TRAB = 'N' THEN 'ACTIVO' ELSE 'NO ACTIVO' END AS ESTADO,
       T.CO_USUA,
       T.TIPO_TRAB,
       P.NO_PERF
FROM TMTRAB T WITH (NOLOCK)
LEFT JOIN TCPERF P WITH (NOLOCK) ON P.CO_PERF = T.CO_PERF
WHERE (@ISDE_BUSQ = ''
       OR ISNULL(T.DE_APEL, '') + ' ' + ISNULL(T.NO_TRAB, '') LIKE '%' + @ISDE_BUSQ + '%'
       OR T.CO_USUA LIKE '%' + @ISDE_BUSQ + '%'
       OR T.NU_DNI LIKE '%' + @ISDE_BUSQ + '%')
  AND (@ISST_INAC = 'S' OR T.ST_TRAB = 'N')
ORDER BY CASE WHEN T.ST_TRAB = 'N' THEN 0 ELSE 1 END, APE_NOM;
GO

-- Mismo permiso que los demás SP del sistema
GRANT EXECUTE ON dbo.SP_TMTRAB_Q02 TO public;
GO

-- Prueba (solo lectura): debe devolver a JULRIOS en Gasocentro y Soyuz
-- EXEC dbo.SP_TMTRAB_Q02 @ISDE_BUSQ = 'JULRIOS', @ISST_INAC = 'N';

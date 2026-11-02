USE GPEBSA;
GO
ALTER PROCEDURE [dbo].[QSP_TMCONT_08_2]           

------------------------------------------------------------           

/*--------------------------------------------------------*/                    

/*---Empresa              : BOLIVAR        --*/                    

/*---Cliente              : BOLIVAR        --*/                    

/*---Sistema              : SISGES        --*/                    

/*---M"dulo               : Empresa        --*/                    

/*---Programa             : Contometros vs Comprobantes --*/                    

/*---           --*/                    

/*---           --*/                    

/*---Script               : QSP_TMCONT_07.sql       --*/                    

/*---Nombre SP            : QSP_TMCONT_07       --*/                    

/*---Desarrollado por     :         --*/                    

/*---Fecha Creaci"n       :              --*/                    

/*---Base Datos           : Microsoft Sql Server       --*/                    

/*---Versi"n              : 2012        --*/                    

/*---Invoca a SP          :         --*/                    

/*---Reemplaza a SP       :         --*/                    

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 1                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/                    

/*--------------------------------------------------------*/                    

/*---- Modificacion 2                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 3                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 4                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 5                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 6                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*--------------------------------------------------------*/                    

/*---- Modificacion 7                                   --*/              

/*---- Modificado por:         --*/            

/*---- Fecha de Modificacion:         --*/           

/*---- Comentario:          --*/           

/*--------------------------------------------------------*/            

/*---- Modificacion 8                                   --*/              

/*---- Modificado por: Victor Dextre Linares     --*/            

/*---- Fecha de Modificacion: 02/12/2014       --*/           

/*---- Comentario: Se modifico reporte para mostrar     --*/           

/*---- valor por descuento, optimizacion de reporte     --*/          

/*--------------------------------------------------------*/                            

/*--------------------------------------------------------*/           

/*---- Modificacion 9                                   --*/              

/*---- Modificado por: WILDER IVAN TORRES     --*/            

/*---- Fecha de Modificacion: 23/09/2015       --*/           

/*---- Comentario: Se modifico reporte para mostrar     --*/           

/*---- el IM_TOTA sin ningun calculo     --*/          

/*--------------------------------------------------------*/                            

/*--------------------------------------------------------*/           

/*---Comentarios          : Contometros vs Comprobantes --*/                    

/*--------------------------------------------------------*/                   

/*---Drop Proc QSP_TMCONT_08        --*/                    

/*---Grant  exec on QSP_TMCONT_08_2 1,1,'20231230','0' to public   --*/                     

/*--------------------------------------------------------*/             

          

  @CO_EMPR TD_TI_001,          

  @CO_ESTA TD_TI_001,          

  @FE_TURN TD_VC_010,          

  @CO_TURN TD_TI_001          

AS          

          

SET NOCOUNT ON          

DECLARE          

@VSNO_GRIF TD_VC_100,          

@VSCO_TDOC_VALE int          

          

          

SELECT @VSNO_GRIF = ''          

SELECT @VSNO_GRIF = DE_SINT_TIPO FROM TTAYUD_FORM WHERE CO_AYUD = 'NGR'          

          

SELECT @VSCO_TDOC_VALE = ''          

SELECT @VSCO_TDOC_VALE = CO_TIPO FROM TTAYUD_FORM WHERE CO_AYUD = 'DES'          

          

IF OBJECT_ID('TEMPDB.DBO.#DESCUENTO') IS NOT NULL            

BEGIN          

       DROP TABLE #DESCUENTO          

END          

          

IF OBJECT_ID('TEMPDB.DBO.#VARILLAJE') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLAJE            

END          

          

IF OBJECT_ID('TEMPDB.DBO.#VARILLAJE_TURNO') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLAJE_TURNO          

END          

          

IF OBJECT_ID('TEMPDB.DBO.#VARILLAJE_TOTA_TURNO') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLAJE_TOTA_TURNO          

END          

          

IF OBJECT_ID('TEMPDB.DBO.#DIFE_VARI') IS NOT NULL            

BEGIN          

       DROP TABLE #DIFE_VARI          

END          

          

IF OBJECT_ID('TEMPDB.DBO.#DIFE_VARI_SIST_CONTO') IS NOT NULL            

BEGIN          

       DROP TABLE #DIFE_VARI_SIST_CONTO          

END          

          

CREATE TABLE #VARILLAJE          

(CA_MEDI NUMERIC(20,10),            

FE_TURN DATETIME,             

CO_PROD INT ,           

CO_TURN INT)          

          

          

--- 11.01.2023          

-- falta filtara por turno          

INSERT INTO #VARILLAJE(CA_MEDI,FE_TURN,CO_PROD,CO_TURN )          

SELECT T1.CA_MEDI,T1.FE_TURN,T2.CO_PROD,T1.CO_TURN          

FROM TTMEDV_TANQ T1 WITH(NOLOCK)           

INNER JOIN TMTANQ T2 WITH(NOLOCK)           

ON T1.CO_TANQ=T2.CO_TANQ          

--WHERE T1.FE_TURN = @FE_TURN --'20230110'          

--AND T1.CO_TURN = @CO_TURN --3          

          

          

          

IF OBJECT_ID('TEMPDB.DBO.#TCDOCU_TDDOCU_COMB_DESP') IS NOT NULL            

BEGIN          

       DROP TABLE #TCDOCU_TDDOCU_COMB_DESP            

END          

          

IF OBJECT_ID('TEMPDB.DBO.#TWDETA_COMB') IS NOT NULL          

BEGIN          

       DROP TABLE #TWDETA_COMB          

END          

      

CREATE TABLE #TCDOCU_COMB(      

 CO_TURN int NULL,      

 CO_ESTA int NOT NULL,      

 CO_FPAG int NULL,      

 CO_PROD int NULL,      

 CO_EMPR int NOT NULL,      

 CO_TDOC int NOT NULL,      

 NU_NSER int NULL,      

 NU_NDOC int NOT NULL,      

 FE_TURN datetime NULL,      

 FE_HORA varchar(6) NULL,      

 NU_NVAL int NULL,      

 FE_EMIS datetime NULL,      

 FE_EMIS_HORA varchar(6) NULL,      

 IM_VNET numeric(20,10) NULL,      

 IM_VVEN numeric(20,10) NULL,      

 IM_IGV numeric(20,10) NULL,      

 IM_DESC numeric(20,10) NULL,      

 IM_TOTA numeric(20,10) NULL,      

 NU_GALN numeric(9,4) NULL,      

 NU_PREV numeric(9,4) NULL,      

 IM_PAGO numeric(20,10) NULL,      

 NU_LADO int NULL,      

 CO_TMON int NULL,      

 DE_PLAC varchar(8) NULL,      

 NU_KILM varchar(20) NULL,      

 NU_PVENT int NULL,      

 NU_TDOC_FACT int NULL,      

 NU_NSER_FACT int NULL,      

 NU_NDOC_FACT int NULL,      

 ST_DVEN varchar(1) NOT NULL,      

 CO_CHOF int NULL,      

 CO_CLIE int NULL,      

 NU_LIQI varchar(15) NULL,      

 ST_CANJ varchar(1) NULL,      

 ST_LIQI varchar(3) NULL,      

 ST_PERI varchar(3) NULL,      

 ST_ANIO varchar(3) NULL,      

 CO_TRAB int NULL,      

 CO_VEHI smallint NULL,      

 CO_USUA_CREA varchar(8) NULL,      

 FE_USUA_CREA datetime NULL,      

 CO_USUA_MODI varchar(8) NULL,      

 FE_USUA_MODI datetime NULL,      

 NU_IGV numeric(9,4) NULL,      

 NU_DIST_RECO numeric(16,14) NULL,      

 CO_TDES_DOCU varchar(1) NULL,      

 NO_CLIE_D1_DNI varchar(10) NULL,      

 NO_CLIE_D1_APE varchar(50) NULL,      

 ST_EMIS varchar(1) NULL,      

 FE_CREA_DOCU datetime NULL,      

 FE_VENC datetime NULL,      

 DE_OBSE varchar(500) NULL,      

 FE_DOCU_ORIG datetime NULL,      

 TI_LIQI varchar(3) NULL,      

 CO_EMPR_LIQI varchar(2) NULL,      

 CO_ESTA_LIQI varchar(3) NULL,      

 IM_PREC_PACT numeric(9,4) NULL,      

 NU_IDTR bigint NULL,      

 IM_BRUT_INAF numeric(16,4) NULL,      

 NU_CORR_VENT bigint NULL,      

 TI_FACT varchar(3) NULL,      

 DE_PLACS varchar(50) NULL,      

 IM_TOTA_FACT numeric(16,4) NULL,      

 CO_NSER varchar(4) NOT NULL,      

 CO_NSER_FACT varchar(4) NULL,      

 PRIMARY KEY CLUSTERED       

(      

 CO_EMPR ASC,      

 CO_ESTA ASC,      

 CO_TDOC ASC,      

 NU_NDOC ASC,      

 CO_NSER ASC      

))      

      

insert into #TCDOCU_COMB      

EXEC [SP_TMDOCU_CLIE_Q01] @FE_TURN     



      

UPDATE #TCDOCU_COMB      

SET NU_GALN=NU_GALN*-1,IM_TOTA=IM_TOTA*-1      

WHERE      

CO_TDOC=5      

      

          

SELECT T2.CO_EMPR,T2.CO_ESTA,T2.CO_TDOC,T2.CO_NSER,T2.NU_NDOC,          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.CO_PROD))),0 ) > 0 AND T1.CO_PROD > 0 THEN T1.CO_PROD ELSE T2.CO_PROD END) 'CO_PROD',          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_PREV))),0 ) > 0 AND T1.NU_PREV > 0 THEN T1.NU_PREV ELSE T2.NU_PREV END) 'NU_PREV',          

SUM((CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_GALN))),0 ) > 0 AND T1.NU_GALN > 0 THEN T1.NU_GALN ELSE T2.NU_GALN END)) 'NU_GALN',          

SUM((CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.IM_TOTA))),0 ) > 0 AND T1.IM_TOTA > 0 THEN T1.IM_TOTA ELSE T2.IM_TOTA END)) 'IM_TOTA'          

INTO #TWDETA_COMB          

FROM TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN TDDOCU_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN=  @FE_TURN           

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

AND T1.ST_DVEN='N'           

GROUP BY T2.CO_EMPR,T2.CO_ESTA,T2.CO_TDOC,T2.CO_NSER,T2.NU_NDOC,          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.CO_PROD))),0 ) > 0 AND T1.CO_PROD > 0 THEN T1.CO_PROD ELSE T2.CO_PROD END),          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_PREV))),0 ) > 0 AND T1.NU_PREV > 0 THEN T1.NU_PREV ELSE T2.NU_PREV END)         

UNION ALL      

SELECT T2.CO_EMPR,T2.CO_ESTA,T2.CO_TDOC,T2.CO_NSER,T2.NU_NDOC,          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.CO_PROD))),0 ) > 0 AND T1.CO_PROD > 0 THEN T1.CO_PROD ELSE T2.CO_PROD END) 'CO_PROD',          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_PREV))),0 ) > 0 AND T1.NU_PREV > 0 THEN T1.NU_PREV ELSE T2.NU_PREV END) 'NU_PREV',          

SUM((CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_GALN))),0 ) > 0 AND T1.NU_GALN > 0 THEN T1.NU_GALN ELSE T2.NU_GALN END)) 'NU_GALN',          

SUM((CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.IM_TOTA))),0 ) > 0 AND T1.IM_TOTA > 0 THEN T1.IM_TOTA ELSE T2.IM_TOTA END)) 'IM_TOTA'   

FROM #TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN TDDOCU_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN=  @FE_TURN           

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

AND T1.ST_DVEN='N'           

GROUP BY T2.CO_EMPR,T2.CO_ESTA,T2.CO_TDOC,T2.CO_NSER,T2.NU_NDOC,          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.CO_PROD))),0 ) > 0 AND T1.CO_PROD > 0 THEN T1.CO_PROD ELSE T2.CO_PROD END),          

(CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(T1.NU_PREV))),0 ) > 0 AND T1.NU_PREV > 0 THEN T1.NU_PREV ELSE T2.NU_PREV END)         

      

          

          

SELECT          

T1.CO_TURN,          

T1.FE_TURN,T1.NU_NDOC,T1.CO_NSER,T1.CO_TDOC,T1.ST_DVEN,T1.CO_TDES_DOCU,          

(CASE WHEN ISNULL(T2.NU_GALN,0) > 0 THEN T2.NU_GALN ELSE T1.NU_GALN END) 'NU_GALN',          

(CASE WHEN ISNULL(T2.NU_PREV,0) > 0 THEN T2.NU_PREV ELSE T1.NU_PREV END) 'NU_PREV',          

(CASE WHEN ISNULL(T2.CO_PROD,0) > 0 THEN T2.CO_PROD ELSE T1.CO_PROD END) 'CO_PROD',          

ISNULL(T1.IM_TOTA,0) 'IM_TOTA'          

--ISNULL(ROUND((CASE WHEN RTRIM(LTRIM(@VSCO_TDOC_VALE)) = T1.CO_TDOC THEN T1.IM_TOTA - (T1.IM_DESC*(1+T1.NU_IGV)) ELSE T1.IM_TOTA/*+T1.IM_DESC*/ END),2),0) 'IM_TOTA'          

INTO #TCDOCU_TDDOCU_COMB_DESP          

FROM TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN #TWDETA_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN=  @FE_TURN           

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

AND T1.ST_DVEN='N'        

UNION ALL      

SELECT          

T1.CO_TURN,          

T1.FE_TURN,T1.NU_NDOC,T1.CO_NSER,T1.CO_TDOC,T1.ST_DVEN,T1.CO_TDES_DOCU,          

(CASE WHEN ISNULL(T2.NU_GALN,0) > 0 THEN T2.NU_GALN ELSE T1.NU_GALN END) 'NU_GALN',          

(CASE WHEN ISNULL(T2.NU_PREV,0) > 0 THEN T2.NU_PREV ELSE T1.NU_PREV END) 'NU_PREV',          

(CASE WHEN ISNULL(T2.CO_PROD,0) > 0 THEN T2.CO_PROD ELSE T1.CO_PROD END) 'CO_PROD',          

ISNULL(T1.IM_TOTA,0) 'IM_TOTA'          

--ISNULL(ROUND((CASE WHEN RTRIM(LTRIM(@VSCO_TDOC_VALE)) = T1.CO_TDOC THEN T1.IM_TOTA - (T1.IM_DESC*(1+T1.NU_IGV)) ELSE T1.IM_TOTA/*+T1.IM_DESC*/ END),2),0) 'IM_TOTA'            

FROM #TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN #TWDETA_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN=  @FE_TURN           

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

AND T1.ST_DVEN='N'           

          

IF OBJECT_ID('TEMPDB.DBO.#TCDOCU_TDDOCU_COMB_DESC') IS NOT NULL            

BEGIN          

       DROP TABLE #TCDOCU_TDDOCU_COMB_DESC            

END          

          

          

SELECT           

       /*SUM(ISNULL(T1.IM_DESC*1.18, ISNULL(T2.IM_DESC*1.18,0)))*/          

       SUM(             

     ISNULL(          

             

   /*(CASE WHEN ISNULL(T1.IM_PREC_PACT,0) > 0           

   THEN ROUND(ISNULL(ISNULL(T1.NU_PREV,T2.NU_PREV),0)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0),2) -           

          (CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*ROUND(ISNULL(T1.IM_PREC_PACT,0)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0),2)            

   ELSE 0 END)*/          

          

   /*ROUND(((CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*(T1.IM_DESC)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0)),2) */          

   ROUND(((CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*(T1.IM_DESC)/**ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0)*/),2)           

          

     ,0)                 )'IM_DESC',          

       (CASE WHEN ISNULL(T2.CO_PROD,0) > 0 THEN T2.CO_PROD ELSE T1.CO_PROD END) 'CO_PROD',           

       T1.FE_TURN           

INTO #TCDOCU_TDDOCU_COMB_DESC          

FROM TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN #TWDETA_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA           

AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

LEFT JOIN TTTIPO_DESC_DOCU T3 WITH(NOLOCK)          

ON T1.CO_TDES_DOCU = T3.CO_TDES_DOCU           

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN= @FE_TURN          

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)                    

AND T1.ST_DVEN='N'           

AND ISNULL(T3.ST_DESC_DOCU,'N') = 'S' ----AND ISNULL(T3.ST_CRED,'N') = 'n'          

GROUP BY T1.CO_PROD, T1.FE_TURN,T2.CO_PROD          

--select * from #TCDOCU_TDDOCU_COMB_DESC      

    

    

UNION ALL    

    

SELECT           

       /*SUM(ISNULL(T1.IM_DESC*1.18, ISNULL(T2.IM_DESC*1.18,0)))*/          

       SUM(             

     ISNULL(          

             

   /*(CASE WHEN ISNULL(T1.IM_PREC_PACT,0) > 0           

   THEN ROUND(ISNULL(ISNULL(T1.NU_PREV,T2.NU_PREV),0)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0),2) -           

          (CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*ROUND(ISNULL(T1.IM_PREC_PACT,0)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0),2)            

   ELSE 0 END)*/          

          

   /*ROUND(((CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*(T1.IM_DESC)*ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0)),2) */          

   ROUND(((CASE WHEN @VSCO_TDOC_VALE = T1.CO_TDOC THEN (1+T1.NU_IGV) ELSE 1 END)*(T1.IM_DESC)/**ISNULL(ISNULL(T1.NU_GALN,T2.NU_GALN),0)*/),2)           

          

     ,0)          

       )'IM_DESC',          

       (CASE WHEN ISNULL(T2.CO_PROD,0) > 0 THEN T2.CO_PROD ELSE T1.CO_PROD END) 'CO_PROD',           

       T1.FE_TURN                

FROM #TCDOCU_COMB T1 WITH(NOLOCK)          

LEFT JOIN #TWDETA_COMB T2 WITH(NOLOCK)           

ON  T1.[CO_EMPR]=T2.[CO_EMPR]          

AND T1.[CO_ESTA]=T2.CO_ESTA           

AND T1.[CO_NSER]=T2.[CO_NSER] AND T1.[NU_NDOC]=T2.[NU_NDOC] AND T1.CO_TDOC = T2.CO_TDOC          

LEFT JOIN TTTIPO_DESC_DOCU T3 WITH(NOLOCK)          

ON T1.CO_TDES_DOCU = T3.CO_TDES_DOCU           

WHERE (T1.CO_TDOC != 8)              

AND T1.FE_TURN= @FE_TURN          

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)                    

AND T1.ST_DVEN='N'           

AND ISNULL(T3.ST_DESC_DOCU,'N') = 'S' ----AND ISNULL(T3.ST_CRED,'N') = 'n'          

GROUP BY T1.CO_PROD, T1.FE_TURN,T2.CO_PROD          

--select * from #TCDOCU_TDDOCU_COMB_DESC      

    

    

    

    

    

    

    

    

SELECT           

       @VSNO_GRIF AS 'GRIFO',M.FE_TURN,4'TIPOREG',          

       'IMPORTE DESCUENTO SOBRE EL CONTADO(S/.)'AS'DSC',          

       ISNULL([101010],0)'G84',          

    ISNULL([101020],0)'G90',           

    ISNULL([101030],0)'G95',           

    ISNULL([101040],0)'G97',          

       ISNULL([101050],0)'GD2',          

    ISNULL([101060],0)'GD1',           

    ISNULL([101070],0)'GLP',           

    ISNULL([310838],0)'GNV',          

    ISNULL([101080],0)'UR',          

    0 AS 'TOTGLN',          

       (ISNULL([101010],0) + ISNULL([101020],0) + ISNULL([101030],0) + ISNULL([101040],0) +          

        ISNULL([101050],0) + ISNULL([101060],0) + ISNULL([101070],0) + ISNULL([310838],0) +           

  ISNULL([101080],0))  'TOT'          

INTO #DESCUENTO          

FROM          

(           

       SELECT IM_DESC,CO_PROD,FE_TURN FROM  #TCDOCU_TDDOCU_COMB_DESC          

       WHERE FE_TURN=@FE_TURN          

)           

AS P          

PIVOT          

(          

       SUM(P.IM_DESC)          

       FOR           

       P.CO_PROD IN ( [101010], [101020],[101070],[101050], [101030], [101040], [101060],[310838], [101080])          

) AS M          

          

DECLARE @TM_RESCONMECAFIN TABLE(          

       IDREG INT IDENTITY,         

       IDREGREP int,          

       DESCRREP VARCHAR(100),          

       DESCR VARCHAR(100),          

       COMB1 NUMERIC (15,3) DEFAULT 0,          

       SOLE1 NUMERIC (15,3) DEFAULT 0,          

       COMB2 NUMERIC (15,3) DEFAULT 0,          

       SOLE2 NUMERIC (15,3) DEFAULT 0,          

       COMB3 NUMERIC (15,3) DEFAULT 0,          

       SOLE3 NUMERIC (15,3) DEFAULT 0,          

       COMB4 NUMERIC (15,3) DEFAULT 0,          

       SOLE4 NUMERIC (15,3) DEFAULT 0,          

       COMB5 NUMERIC (15,3) DEFAULT 0,          

       SOLE5 NUMERIC (15,3) DEFAULT 0,          

       COMB6 NUMERIC (15,3) DEFAULT 0,          

       SOLE6 NUMERIC (15,3) DEFAULT 0,          

       COMB7 NUMERIC (15,3) DEFAULT 0,          

       SOLE7 NUMERIC (15,3) DEFAULT 0,          

       COMB8 NUMERIC (15,3) DEFAULT 0,          

       SOLE8 NUMERIC (15,3) DEFAULT 0,          

       COMB9 NUMERIC (15,3) DEFAULT 0,          

       SOLE9 NUMERIC (15,3) DEFAULT 0,          

       TOTGL NUMERIC (15,3) DEFAULT 0,          

       TOTSO NUMERIC (15,3) DEFAULT 0          

)           

          

--MECANICOS          

          

DECLARE @VNROREGI INT          

DECLARE @RMEC1 INT          

DECLARE @RMEC2 INT          

DECLARE @RPAG1 INT          

DECLARE @RPAG2 INT          

DECLARE @IDREGREP int          

DECLARE @DESCRREP VARCHAR(100)          

DECLARE @DESCR VARCHAR(100)          

DECLARE @RMIN INT          

DECLARE @RMAX INT          

          

DECLARE @TBGAL TABLE           

(          

       IDREG INT IDENTITY, CODARTICULO INT, CODLADO int, NOMBRECORTO VARCHAR(50), GALONES NUMERIC(15,3),PRECIO MONEY, TOTSO NUMERIC(15,3)          

)          

          

SELECT  @IDREGREP = 1          

SELECT  @DESCRREP = 'PARTE DE COMBUSTIBLE (MECANICO)'          

SELECT  @DESCR = 'GALONES DESPACHADOS SEGÚN CONTÓMETRO'          

          

DELETE @TBGAL          

          

          

INSERT INTO @TBGAL          

SELECT           

       CO_PROD, CO_LADO, NO_PROD, SUM(TO_GALN) AS TO_GALN,(CASE WHEN @CO_TURN > 0 THEN IM_VENT ELSE NU_PREC END),SUM(TOTSOL) AS TOTSOL           

FROM (          

       SELECT           

     T1.CO_TURN,T2.CO_PROD,T2.CO_LADO,ISNULL(T3.DE_PROD_CORT,'')  AS NO_PROD,T3.IM_VENT,          

     SUM(CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END) 'TO_GALN',            

     ( SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)*(ISNULL(T2.IM_PRE1,0)))          

     /(CASE WHEN SUM (CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)  =0 THEN 1 ELSE   SUM (CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END) END) ) 'NU_PREC',           

     SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END) *(T2.IM_PRE1)) 'TOTSOL'
       FROM TCCONT T1 WITH(NOLOCK)           

       INNER JOIN TDCONT T2 WITH(NOLOCK)          

       ON T1.CO_CONT = T2.CO_CONT           

       INNER JOIN TMPROD T3 WITH(NOLOCK)          

       ON T2.CO_PROD = T3.CO_PROD          

       WHERE T1.CO_EMPR = @CO_EMPR          

       AND T1.CO_ESTA = @CO_ESTA          

       AND T1.FE_TURN =  @FE_TURN          

       AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)--AND T1.CO_TURN = @CO_TURN          

       GROUP BY T1.CO_TURN,T2.CO_PROD, T2.CO_LADO, T3.DE_PROD_CORT,T3.IM_VENT          

) TG          

GROUP BY CO_PROD, CO_LADO, NO_PROD,(CASE WHEN @CO_TURN > 0 THEN IM_VENT ELSE NU_PREC END)          

          

SELECT @RMIN = MIN(IDREG), @RMAX = MAX(IDREG) FROM @TBGAL          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

          

WHILE @RMAX > = @RMIN          

BEGIN          

       UPDATE @TM_RESCONMECAFIN SET            

     COMB1 = COMB1 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101010 ),0) ,          

     COMB2 = COMB2 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101020  ),0) ,          

     COMB3 = COMB3 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101030  ),0) ,          

     COMB4 = COMB4 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101040  ),0) ,          

     COMB5 = COMB5 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101050  ),0) ,          

     COMB6 = COMB6 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101060  ),0) ,          

     COMB7 = COMB7 + ISNULL((SELECT (GALONES/ 3.7853) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101070  ),0) ,          

     COMB8 = COMB8 + ISNULL((SELECT (GALONES/ 3.7853) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 310838  ),0) ,          

  --COMB9 = COMB9 + ISNULL((SELECT (GALONES/ 3.7853) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0) ,          

  COMB9 = COMB9 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0) ,          

     TOTGL = TOTGL + ISNULL((SELECT GALONES*(CASE WHEN CODARTICULO IN (101070,310838) THEN (1/ 3.7853) ELSE 1 END)           

        FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838,101080) ),0) ,          

     TOTSO = TOTSO + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838,101080)),0)          

       WHERE IDREG = @VNROREGI          

       SELECT  @RMIN = @RMIN + 1          

END          

          

-- CALIBRACIONES          

          

DELETE @TBGAL          

          

INSERT INTO @TBGAL          

SELECT           

       T2.CO_PROD,T2.CO_LADO,ISNULL(T3.DE_PROD_CORT,'')  AS NO_PROD,           

       SUM(ISNULL(IM_CALI,0)) 'TO_GALN',            

       ( SUM(ISNULL(IM_CALI,0)*(ISNULL(T2.IM_PRE1,0)))          

       /(CASE WHEN SUM (ISNULL(IM_CALI,0))  =0 THEN 1 ELSE   SUM (ISNULL(IM_CALI,0)) END)   )         'NU_PREC',           

       SUM((ISNULL(IM_CALI,0)) *(T2.IM_PRE1)) 'TOTSOL'          

FROM TCCONT T1 WITH(NOLOCK)           

INNER JOIN TDCONT T2 WITH(NOLOCK)          

ON T1.CO_CONT = T2.CO_CONT           

INNER JOIN TMPROD T3 WITH(NOLOCK)          

ON T2.CO_PROD = T3.CO_PROD          

WHERE T1.CO_EMPR = @CO_EMPR          

AND T1.CO_ESTA = @CO_ESTA          

AND T1.FE_TURN=  @FE_TURN          

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

AND T2.IM_CALI >0          

GROUP BY T2.CO_PROD, T2.CO_LADO, T3.DE_PROD_CORT          

            

          

SELECT @RMIN = MIN(IDREG), @RMAX = MAX(IDREG) FROM @TBGAL          

SELECT  @IDREGREP = 1          

SELECT  @DESCRREP = 'PARTE DE COMBUSTIBLE (MECANICO)'          

SELECT  @DESCR = 'CALIBRACIONES (-)'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

          

WHILE @RMAX > = @RMIN          

BEGIN          

       UPDATE @TM_RESCONMECAFIN SET            

     COMB1 = COMB1 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101010 ),0) ,          

     COMB2 = COMB2 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101020  ),0) ,          

     COMB3 = COMB3 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101030  ),0) ,          

     COMB4 = COMB4 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101040  ),0) ,          

     COMB5 = COMB5 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101050  ),0) ,          

     COMB6 = COMB6 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101060  ),0) ,          

     COMB7 = COMB7 + ISNULL((SELECT (GALONES/ 3.7853) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101070  ),0) ,          

     COMB8 = COMB8 + ISNULL((SELECT (GALONES/ 3.7853) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 310838  ),0) ,          

     --COMB9 = COMB9 + ISNULL((SELECT (GALONES/ 3.7854) FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0) ,          

  COMB9 = COMB9 + ISNULL((SELECT GALONES FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0) ,        

     TOTGL = TOTGL + ISNULL((SELECT GALONES*(CASE WHEN CODARTICULO IN (101070,310838) THEN (1/ 3.7853) ELSE 1 END)           

        FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838, 101080) ),0) ,          

     TOTSO = TOTSO + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838, 101080)),0)          

       WHERE IDREG = @VNROREGI          

          

       SELECT  @RMIN = @RMIN + 1          

          

END          

          

----------------------          

SELECT  @IDREGREP = 1          

SELECT  @DESCRREP = 'PARTE DE COMBUSTIBLE (MECANICO)'          

SELECT  @DESCR = 'GALONES VENDIDOS SEGÚN CONTÓMETRO'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

SELECT @RMIN =MIN(IDREG) , @RMAX =(MAX(IDREG) -1) FROM @TM_RESCONMECAFIN          

--TOTAL VENTA SEGÚN CONTOMETRO S/.          

SELECT  @RMEC1 = MAX(IDREG) FROM @TM_RESCONMECAFIN          

WHILE @RMAX >  @RMIN          

BEGIN          

       UPDATE @TM_RESCONMECAFIN SET          

       COMB1 = COMB1 + ((SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB2 = COMB2 + ((SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB3 = COMB3 + ((SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB4 = COMB4 + ((SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB5 = COMB5 + ((SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB6 = COMB6 + ((SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB7 = COMB7 + ((SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       COMB8 = COMB8 + ((SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

    COMB9 = COMB9 + ((SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       TOTGL = TOTGL + ((SELECT TOTGL FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT TOTGL FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1)),          

       TOTSO = TOTSO + ((SELECT TOTSO FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN) - (SELECT TOTSO FROM @TM_RESCONMECAFIN WHERE IDREG = @RMIN+1))          

       WHERE IDREG = @VNROREGI          

          

       SELECT  @RMIN = @RMIN + 1          

END          

          

---TOTAL VENDIDOS          

          

DELETE @TBGAL          

          

INSERT INTO @TBGAL(CODARTICULO, GALONES, PRECIO, TOTSO)          

SELECT           

       T2.CO_PROD,           

       SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) 'TO_GALN',            

       ( SUM(((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))*(ISNULL(T2.IM_PRE1,0)))          

       /(CASE WHEN SUM ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))  =0 THEN 1           

     ELSE SUM ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) END)   )         'NU_PREC',           

       SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END) *(T2.IM_PRE1)) 'TOTSOL'
FROM TCCONT T1 WITH (NOLOCK)           

INNER JOIN TDCONT T2 WITH (NOLOCK)          

ON T1.CO_CONT = T2.CO_CONT           

WHERE T1.CO_EMPR =@CO_EMPR          

AND T1.CO_ESTA =@CO_ESTA          

AND T1.FE_TURN= @FE_TURN          

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

GROUP BY T2.CO_PROD          

          

SELECT @RMIN = MIN(IDREG), @RMAX = MAX(IDREG) FROM @TBGAL          

          

SELECT  @IDREGREP = 1          

SELECT  @DESCRREP = 'PARTE DE COMBUSTIBLE (MECANICO)'          

SELECT  @DESCR = 'TOTAL VENTA SEGÚN CONTOMETRO S/.'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

          

SELECT  @RMEC2 = MAX(IDREG) FROM @TM_RESCONMECAFIN          

          

WHILE @RMAX > = @RMIN          

BEGIN          

          

       UPDATE @TM_RESCONMECAFIN SET            

     COMB1 = COMB1 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101010 ),0) ,          

     COMB2 = COMB2 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101020  ),0) ,          

     COMB3 = COMB3 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101030  ),0) ,          

     COMB4 = COMB4 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101040  ),0) ,          

     COMB5 = COMB5 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101050  ),0) ,          

     COMB6 = COMB6 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101060  ),0) ,          

     COMB7 = COMB7 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101070  ),0) ,          

     COMB8 = COMB8 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 310838  ),0),          

  COMB9 = COMB9 + ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0)          

       WHERE IDREG = @VNROREGI          

          

       SELECT  @RMIN = @RMIN + 1          

END          

          

-----------------          

--- (-) CALIBRACIONES          

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^          

DELETE @TBGAL          

INSERT INTO @TBGAL(CODARTICULO, GALONES, PRECIO, TOTSO)          

SELECT           

       T2.CO_PROD,           

       SUM(ISNULL(IM_CALI,0)) 'TO_GALN',            

       ( SUM((ISNULL(IM_CALI,0))*(ISNULL(T2.IM_PRE1,0)))          

       /(CASE WHEN SUM (ISNULL(IM_CALI,0))  =0 THEN 1 ELSE   SUM (ISNULL(IM_CALI,0)) END)) 'NU_PREC',           

       SUM(ISNULL(IM_CALI,0) *(T2.IM_PRE1)) 'TOTSOL'          

FROM TCCONT T1 WITH (NOLOCK)           

INNER JOIN TDCONT T2 WITH(NOLOCK)          

ON T1.CO_CONT = T2.CO_CONT           

WHERE T1.CO_EMPR = @CO_EMPR          

AND T1.CO_ESTA = @CO_ESTA          

AND T1.FE_TURN=  @FE_TURN          

AND T1.CO_TURN = (CASE WHEN @CO_TURN = 0 THEN T1.CO_TURN ELSE @CO_TURN END)          

--AND T1.CO_TURN = @CO_TURN          

AND T2.IM_CALI >0          

GROUP BY T2.CO_PROD          

          

SELECT  @RMEC2 = MAX(IDREG) FROM @TM_RESCONMECAFIN          

SELECT @RMIN = MIN(IDREG), @RMAX = MAX(IDREG) FROM @TBGAL          

WHILE @RMAX > = @RMIN          

BEGIN          

          

       UPDATE @TM_RESCONMECAFIN SET            

     COMB1 = COMB1 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101010 ),0) ,          

     COMB2 = COMB2 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101020  ),0) ,          

     COMB3 = COMB3 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101030  ),0) ,          

     COMB4 = COMB4 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101040  ),0) ,          

     COMB5 = COMB5 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101050  ),0) ,          

     COMB6 = COMB6 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101060  ),0) ,          

     COMB7 = COMB7 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101070  ),0) ,          

     COMB8 = COMB8 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 310838  ),0),          

  COMB9 = COMB9 - ISNULL((SELECT TOTSO FROM @TBGAL WHERE IDREG = @RMIN AND CODARTICULO = 101080  ),0)          

      WHERE IDREG = @VNROREGI          

          

       SELECT  @RMIN = @RMIN + 1          

END          

          

          

          

--02/10/2007          

-----------------------------------------------          

-- TOTAL POR DOCUMENTO          

-----------------------------------------------          

          

DECLARE @@TM_RESCONMECAFIN TABLE (           

       IDREG INT IDENTITY,          

       TIPDOC int,          

       NUMSER VARCHAR(4),          

       NROMIN INT,          

       NROMAX INT,          

       NROANU INT,          

       COMB1 NUMERIC (15,3) DEFAULT 0,          

       SOLE1 NUMERIC (15,3) DEFAULT 0,          

       COMB2 NUMERIC (15,3) DEFAULT 0,          

       SOLE2 NUMERIC (15,3) DEFAULT 0,          

       COMB3 NUMERIC (15,3) DEFAULT 0,          

       SOLE3 NUMERIC (15,3) DEFAULT 0,          

       COMB4 NUMERIC (15,3) DEFAULT 0,          

       SOLE4 NUMERIC (15,3) DEFAULT 0,          

       COMB5 NUMERIC (15,3) DEFAULT 0,          

       SOLE5 NUMERIC (15,3) DEFAULT 0,          

       COMB6 NUMERIC (15,3) DEFAULT 0,          

       SOLE6 NUMERIC (15,3) DEFAULT 0,          

       COMB7 NUMERIC (15,3) DEFAULT 0,          

       SOLE7 NUMERIC (15,3) DEFAULT 0,          

       COMB8 NUMERIC (15,3) DEFAULT 0,          

       SOLE8 NUMERIC (15,3) DEFAULT 0,          

       COMB9 NUMERIC (15,3) DEFAULT 0,          

       SOLE9 NUMERIC (15,3) DEFAULT 0,          

       TOTGL NUMERIC (15,3) DEFAULT 0,          

       TOTSO NUMERIC (15,3) DEFAULT 0          

)           

          

DECLARE @TOT_GAL TABLE           

(IDREG INT IDENTITY, CODARTICULO INT,  CANTIDAD NUMERIC(15,3) , IMPORTEVENTA MONEY)          

          

DECLARE @RMIN_1 INT          

DECLARE @RMAX_1 INT          

DECLARE @VANULAD INT          

DECLARE @VDOCMIN INT          

DECLARE @VDOCMAX INT          

          

DECLARE @TMP_TIPDOCSER TABLE           

(IDREG INT IDENTITY, TIPODOCUMENTO int, NUMSERIE VARCHAR(4))          

          

DECLARE           

@TOTGALDOCUG1 NUMERIC (15,3)          

,@TOTGALDOCUG2 NUMERIC (15,3)          

,@TOTGALDOCUG3 NUMERIC (15,3)                  

,@TOTGALDOCUG4 NUMERIC (15,3)          

,@TOTGALDOCUG5 NUMERIC (15,3)          

,@TOTGALDOCUG6 NUMERIC (15,3)          

,@TOTGALDOCUG7 NUMERIC (15,3)          

,@TOTGALDOCUG8 NUMERIC (15,3)          

,@TOTGALDOCUG9 NUMERIC (15,3)          

          

,@TOTSOLDOCUG1 NUMERIC (15,3)          

,@TOTSOLDOCUG2 NUMERIC (15,3)          

,@TOTSOLDOCUG3 NUMERIC (15,3)          

,@TOTSOLDOCUG4 NUMERIC (15,3)          

,@TOTSOLDOCUG5 NUMERIC (15,3)          

,@TOTSOLDOCUG6 NUMERIC (15,3)          

,@TOTSOLDOCUG7 NUMERIC (15,3)          

,@TOTSOLDOCUG8 NUMERIC (15,3)          

,@TOTSOLDOCUG9 NUMERIC (15,3)          

          

DECLARE @TMVTA_ TABLE           

(CO_TDOC int, FE_TURN DATETIME, CO_TURN int,           

CO_NSER VARCHAR(4), CO_PROD INT, NU_GALN NUMERIC(9,4),           

IM_TOTA NUMERIC(20,10))          

          

SELECT  @TOTGALDOCUG1 = 0          

SELECT  @TOTGALDOCUG2 = 0          

SELECT  @TOTGALDOCUG3 = 0          

SELECT  @TOTGALDOCUG4 = 0          

SELECT  @TOTGALDOCUG5 = 0          

SELECT  @TOTGALDOCUG6 = 0           

SELECT  @TOTGALDOCUG7 = 0          

SELECT  @TOTSOLDOCUG1 = 0          

SELECT  @TOTSOLDOCUG2 = 0          

SELECT  @TOTSOLDOCUG3 = 0          

SELECT  @TOTSOLDOCUG4 = 0          

SELECT  @TOTSOLDOCUG5 = 0          

SELECT  @TOTSOLDOCUG6 = 0          

SELECT  @TOTSOLDOCUG7 = 0          

SELECT  @TOTSOLDOCUG8 = 0          

SELECT  @TOTSOLDOCUG9 = 0          

          

INSERT INTO @TMP_TIPDOCSER(TIPODOCUMENTO, NUMSERIE)          

SELECT           

       CO_TDOC, CO_NSER          

FROM #TCDOCU_TDDOCU_COMB_DESP          

WHERE CO_TDOC IN (1,2,3,5,7,8,15,17,18)          

AND FE_TURN=  @FE_TURN          

AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)          

GROUP BY CO_TDOC, CO_NSER          

ORDER BY CO_TDOC, CO_NSER          

          

SELECT  @RMIN =MIN(IDREG) , @RMAX =MAX(IDREG) FROM @TMP_TIPDOCSER          

          

WHILE @RMAX > =  @RMIN          

BEGIN          

          

       SELECT @VANULAD = COUNT(ST_DVEN)  FROM #TCDOCU_TDDOCU_COMB_DESP           

       WHERE CO_TDOC = (SELECT TIPODOCUMENTO FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN = @CO_TURN          

       AND ST_DVEN = 'A'           

       AND CO_NSER = (SELECT NUMSERIE FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)          

          

          

       SELECT @VDOCMIN = MIN(NU_NDOC), @VDOCMAX = MAX(NU_NDOC) FROM #TCDOCU_TDDOCU_COMB_DESP           

       WHERE CO_TDOC = (SELECT TIPODOCUMENTO FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN = @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_NSER = (SELECT NUMSERIE FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)          

          

       INSERT INTO @@TM_RESCONMECAFIN(TIPDOC, NUMSER, NROMIN, NROMAX, NROANU)          

       SELECT (SELECT TIPODOCUMENTO FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN), (SELECT NUMSERIE FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN),@VDOCMIN, @VDOCMAX, @VANULAD          

       SELECT  @VNROREGI = @@IDENTITY             

          

       DELETE @TOT_GAL            

          

       SELECT @TOTSOLDOCUG1 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG1 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101010                               

          

       SELECT @TOTSOLDOCUG2 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG2 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101020                                   

          

       SELECT @TOTSOLDOCUG3 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG3 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101030          

          

       SELECT @TOTSOLDOCUG4 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG4 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101040          

          

       SELECT @TOTSOLDOCUG5 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG5 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101050          

          

       SELECT @TOTSOLDOCUG6 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG6 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101060          

          

       SELECT @TOTSOLDOCUG7 = ISNULL(SUM(IM_TOTA),0), @TOTGALDOCUG7 = ISNULL(SUM(NU_GALN),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8          

       AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101070          

          

       SELECT @TOTSOLDOCUG8 = ISNULL(SUM(ISNULL(IM_TOTA,0)),0), @TOTGALDOCUG8 = ISNULL(SUM(ISNULL(NU_GALN,0)),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8 AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 310838          

          

    SELECT @TOTSOLDOCUG9 = ISNULL(SUM(ISNULL(IM_TOTA,0)),0), @TOTGALDOCUG9 = ISNULL(SUM(ISNULL(NU_GALN,0)),0) FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE CO_TDOC = 8 AND FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN =  @CO_TURN          

       AND ST_DVEN = 'N'          

       AND CO_PROD = 101080          

          

          

       DELETE @TMVTA_          

          

       INSERT INTO @TMVTA_ (CO_TDOC, FE_TURN, CO_TURN, CO_NSER, CO_PROD, NU_GALN, IM_TOTA)          

       SELECT CO_TDOC, FE_TURN, CO_TURN, CO_NSER, CO_PROD, NU_GALN, IM_TOTA          

       FROM #TCDOCU_TDDOCU_COMB_DESP WITH (NOLOCK)          

       WHERE FE_TURN=  @FE_TURN          

       AND CO_TURN = (CASE WHEN @CO_TURN = 0 THEN CO_TURN ELSE @CO_TURN END)--AND CO_TURN = @CO_TURN          

       AND ST_DVEN = 'N'          

          

       INSERT INTO @TOT_GAL (CODARTICULO, CANTIDAD, IMPORTEVENTA)          

       SELECT           

     CO_PROD,          

     (CASE WHEN CO_PROD IN (101070,310838) THEN (SUM( NU_GALN ) / 3.7853)           

     ELSE SUM( NU_GALN ) END) 'NU_GALN',          

     SUM(IM_TOTA) 'IM_TOTA'            

       FROM @TMVTA_          

       WHERE CO_TDOC = (SELECT TIPODOCUMENTO FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)           

       AND CO_NSER = (SELECT NUMSERIE FROM @TMP_TIPDOCSER WHERE IDREG = @RMIN)                  

       GROUP BY CO_PROD, CO_TDOC          

       ORDER BY CO_PROD          

          

       SELECT  @RMIN_1= MIN(IDREG) , @RMAX_1 =MAX(IDREG) FROM @TOT_GAL          

          

       WHILE @RMAX_1 >= @RMIN_1          

       BEGIN          

          

     UPDATE @@TM_RESCONMECAFIN SET            

   COMB1 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101010),COMB1),           

   SOLE1 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101010),SOLE1),            

   COMB2 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101020),COMB2),           

   SOLE2 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101020),SOLE2),            

   COMB3 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101030),COMB3),           

   SOLE3 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101030),SOLE3),            

   COMB4 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101040),COMB4),           

   SOLE4 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101040),SOLE4),            

   COMB5 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101050),COMB5),           

   SOLE5 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101050),SOLE5),            

   COMB6 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101060),COMB6),           

   SOLE6 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101060),SOLE6),            

   COMB7 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101070),COMB7),           

   SOLE7 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101070),SOLE7),            

   COMB8 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 310838),COMB8),           

   SOLE8 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 310838),SOLE8),            

   COMB9 = ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101080),COMB9),           

   SOLE9 = ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1  AND CODARTICULO = 101080),SOLE9),            

          

   TOTGL = ISNULL(TOTGL,0) +           

   ISNULL((SELECT CANTIDAD FROM @TOT_GAL WHERE IDREG  = @RMIN_1 AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838, 101080)),0),          

   TOTSO = ISNULL(TOTSO,0) +           

   ISNULL((SELECT IMPORTEVENTA FROM @TOT_GAL WHERE IDREG  = @RMIN_1 AND CODARTICULO IN (101010,101020,101030,101040,101050,101060,101070,310838, 101080)),0)          

     WHERE IDREG = @VNROREGI          

          

     SELECT  @RMIN_1 = @RMIN_1 + 1                 

       END          

       SELECT  @RMIN = @RMIN + 1                   

          

END          

          

SELECT  @IDREGREP = 3          

SELECT  @DESCRREP = 'COMPROBANTES DE PAGO'          

          

SELECT @RMIN =MAX(IDREG) + 1 FROM @TM_RESCONMECAFIN          

SELECT  @RMIN_1 = @RMIN          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR ,           

             COMB1 , COMB2 , COMB3 , COMB4 , COMB5 ,COMB6, COMB7,COMB8, COMB9,          

    TOTGL, TOTSO,           

    SOLE1, SOLE2, SOLE3, SOLE4, SOLE5, SOLE6, SOLE7, SOLE8, SOLE9 )          

SELECT           

       @IDREGREP, @DESCRREP, UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) +  ' '+ CONVERT(VARCHAR(6), TIPDOC) + ' ' +            

       T1.NUMSER + ' ' +           

       RIGHT(CONVERT(VARCHAR(8), (10000000 + T1.NROMIN)), 7) + ' ' +          

       RIGHT(CONVERT(VARCHAR(8), (10000000 + T1.NROMAX)), 7) + ' ' +           

       RIGHT(CONVERT(VARCHAR(8), (100 + T1.NROANU)),2),          

       T1.COMB1, T1.COMB2, T1.COMB3, T1.COMB4, T1.COMB5, T1.COMB6, T1.COMB7, T1.COMB8, T1.COMB9,           

    T1.TOTGL, T1.TOTSO,          

       T1.SOLE1, T1.SOLE2, T1.SOLE3, T1.SOLE4, T1.SOLE5, T1.SOLE6, T1.SOLE7, T1.SOLE8, T1.SOLE9           

FROM @@TM_RESCONMECAFIN T1           

INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)          

ON T1.TIPDOC = T2.CO_TDOC          

          

----------------------          

          

SELECT @RMAX =MAX(IDREG) FROM @TM_RESCONMECAFIN          

          

SELECT  @IDREGREP = 3          

SELECT  @DESCRREP = 'COMPROBANTES DE PAGO'          

SELECT  @DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

SELECT  @VNROREGI = @@IDENTITY          

          

UPDATE @TM_RESCONMECAFIN SET          

COMB1 = (SELECT SUM(T1.COMB1) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB2 = (SELECT SUM(T1.COMB2) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB3 = (SELECT SUM(T1.COMB3) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB4 = (SELECT SUM(T1.COMB4) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB5 = (SELECT SUM(T1.COMB5) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB6 = (SELECT SUM(T1.COMB6) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB7 = (SELECT SUM(T1.COMB7) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB8 = (SELECT SUM(T1.COMB8) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB9 = (SELECT SUM(T1.COMB9) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

TOTGL = (SELECT SUM(T1.TOTGL) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

TOTSO = (SELECT SUM(T1.TOTSO) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' )           

WHERE IDREG = @VNROREGI          

          

SELECT  @IDREGREP = 3          

SELECT  @DESCRREP = 'COMPROBANTES DE PAGO'          

SELECT  @DESCR = 'TOTAL VENTA SEGÚN SISTEMA S/.'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

--SELECT  @VNROREGI '@VNROREGI',@RPAG2 '@RPAG2'          

--SELECT SUM(T1.SOLE5) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL'           

SELECT @RPAG2 = MAX(IDREG) FROM @TM_RESCONMECAFIN          

          

          

          

UPDATE @TM_RESCONMECAFIN SET          

COMB1 = (SELECT SUM(T1.SOLE1) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB2 = (SELECT SUM(T1.SOLE2) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB3 = (SELECT SUM(T1.SOLE3) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB4 = (SELECT SUM(T1.SOLE4) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB5 = (SELECT SUM(T1.SOLE5) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB6 = (SELECT SUM(T1.SOLE6) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB7 = (SELECT SUM(T1.SOLE7) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB8 = (SELECT SUM(T1.SOLE8) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' ) ,          

COMB9 = (SELECT SUM(T1.SOLE9) FROM @@TM_RESCONMECAFIN T1 INNER JOIN TTTIPO_DOCU T2 WITH(NOLOCK)  ON T1.TIPDOC = T2.CO_TDOC WHERE UPPER(SUBSTRING(T2.DE_NOMB ,1,3)) <> 'CAL' )           

WHERE IDREG = @VNROREGI          

---          

          

SELECT  @IDREGREP = 4          

SELECT  @DESCRREP = ''          

SELECT  @DESCR = 'DIFERENCIA CONTÓMETRO VS SISTEMA GLN'          

          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

          

SELECT  @VNROREGI = @@IDENTITY          

          

UPDATE @TM_RESCONMECAFIN SET          

COMB1 = ( (SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB2 = ( (SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB3 = ( (SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB4 = ( (SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB5 = ( (SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB6 = ( (SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB7 = ( (SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB8 = ( (SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')),           

COMB9 = ( (SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC1) - (SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN'))           

WHERE IDREG = @VNROREGI          

          

---          

SELECT  @IDREGREP = 4          

SELECT  @DESCRREP = ''          

SELECT  @DESCR = 'DIFERENCIA CONTÓMETRO VS SISTEMA S/.'          

INSERT INTO @TM_RESCONMECAFIN(IDREGREP, DESCRREP, DESCR) SELECT @IDREGREP, @DESCRREP, @DESCR          

SELECT  @VNROREGI = @@IDENTITY          

          

UPDATE @TM_RESCONMECAFIN SET          

COMB1 = ( (SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB1 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB2 = ( (SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB2 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB3 = ( (SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB3 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB4 = ( (SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB4 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB5 = ( (SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB5 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB6 = ( (SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB6 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB7 = ( (SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB7 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB8 = ( (SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB8 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) ) ,          

COMB9 = ( (SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE IDREG = @RMEC2) - (SELECT COMB9 FROM @TM_RESCONMECAFIN WHERE IDREG = @RPAG2) )           

WHERE IDREG = @VNROREGI          

          

UPDATE @TM_RESCONMECAFIN SET          

TOTGL = TOTGL - (ISNULL(@TOTGALDOCUG1,0) + ISNULL(@TOTGALDOCUG2,0) + ISNULL(@TOTGALDOCUG3,0) + ISNULL(@TOTGALDOCUG4,0)           

              + ISNULL(@TOTGALDOCUG5,0) + ISNULL(@TOTGALDOCUG6,0) + ISNULL(@TOTGALDOCUG7,0) + ISNULL(@TOTGALDOCUG8,0) + ISNULL(@TOTGALDOCUG9,0)) ,          

          

TOTSO = TOTSO - (ISNULL(@TOTSOLDOCUG1,0) + ISNULL(@TOTSOLDOCUG2,0) + ISNULL(@TOTSOLDOCUG3,0) + ISNULL(@TOTSOLDOCUG4,0)           

              + ISNULL(@TOTSOLDOCUG5,0) + ISNULL(@TOTSOLDOCUG6,0) + ISNULL(@TOTSOLDOCUG7,0)+ ISNULL(@TOTSOLDOCUG8,0) + ISNULL(@TOTSOLDOCUG9,0))          

WHERE IDREG = (SELECT IDREG FROM @TM_RESCONMECAFIN WHERE DESCR = 'TOTAL VENTA SEGÚN SISTEMA GLN')          

          

IF OBJECT_ID('TEMPDB.DBO.#TCCONT_PREV_REGI') IS NOT NULL            

BEGIN          

       DROP TABLE #TCCONT_PREV_REGI                                                                                                                                                       

END          

          

SELECT           

       FE_TURN, CO_PROD,            

       SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))'NU_GALN',          

       (  SUM ( ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))*(ISNULL(T2.IM_PRE1,0)))/(CASE WHEN           

       SUM ( ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)))=0 THEN 1 ELSE    SUM ( ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))) END)   ) 'IM_PRE1',             

       (SUM(((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) *(ISNULL(T2.IM_PRE1,0))) )'TOTAL'
INTO #TCCONT_PREV_REGI          

FROM TCCONT T1 WITH (NOLOCK)          

INNER JOIN TDCONT T2 WITH (NOLOCK)           

ON T1.CO_CONT = T2.CO_CONT                                    

WHERE                                     

FE_TURN = @FE_TURN                                  

GROUP BY T1.FE_TURN, T2.CO_PROD          

          

IF OBJECT_ID('TEMPDB.DBO.#TCCONT_PREV') IS NOT NULL            

BEGIN          

       DROP TABLE #TCCONT_PREV                                             

END          

          

SELECT           

       FE_TURN, CO_PROD, IM_PRE1,             

       CASE           

        WHEN CO_PROD = 101070 THEN SUM((NU_GALN) / 3.7853)          

     WHEN CO_PROD = 101080 THEN SUM((NU_GALN) / 3.7853)          

     ELSE SUM(NU_GALN)           

     END 'VENTA',                                     

       CASE           

        WHEN CO_PROD = 101070 THEN SUM(((NU_GALN) / 3.7853) * IM_PRE1) / (CASE WHEN SUM((NU_GALN) / 3.7853)=0 THEN 1 ELSE SUM((NU_GALN) / 3.7853) END )           

     WHEN CO_PROD = 101080 THEN SUM(((NU_GALN) / 3.7853) * IM_PRE1) / (CASE WHEN SUM((NU_GALN) / 3.7853)=0 THEN 1 ELSE SUM((NU_GALN) / 3.7853) END )           

           ELSE             

            SUM(NU_GALN *IM_PRE1)/ (CASE WHEN SUM(NU_GALN )=0 THEN 1 ELSE SUM(NU_GALN ) END)          

       END 'COSTO'           

INTO #TCCONT_PREV                               

FROM #TCCONT_PREV_REGI                                 

WHERE               

FE_TURN = @FE_TURN                                  

GROUP BY FE_TURN, CO_PROD,IM_PRE1          

ORDER BY FE_TURN            

          

IF OBJECT_ID('TEMPDB.DBO.#TCCONT') IS NOT NULL            

BEGIN          

       DROP TABLE #TCCONT                  

END          

          

SELECT           

       FE_TURN,CO_PROD,(SUM(VENTA*IM_PRE1)/ (CASE WHEN SUM(VENTA)=0 THEN 1 ELSE SUM(VENTA) END))'IM_PRE1',SUM(VENTA)'NU_CONT',          

       SUM(VENTA)*((SUM(VENTA*IM_PRE1)/ (CASE WHEN SUM(VENTA)=0 THEN 1 ELSE SUM(VENTA) END)))'IM_TOTA'            

INTO #TCCONT          

FROM #TCCONT_PREV          

WHERE                                     

FE_TURN = @FE_TURN           

GROUP BY FE_TURN,CO_PROD           

          

IF OBJECT_ID('TEMPDB.DBO.#TMCOMPRA') IS NOT NULL            

BEGIN          

       DROP TABLE #TMCOMPRA                   

END          

          

SELECT           

SUM(ISNULL(T2.CA_COMP_PROD,0)) 'CA_COMP_PROD',           

       ((SUM(ISNULL(T2.CA_COMP_PROD,0)) )*( ( SUM(ISNULL(T2.CA_COMP_PROD,0)*ISNULL(IM_COST_PROM,0))/           

       ( CASE WHEN SUM(ISNULL(T2.CA_COMP_PROD,0))  =0 THEN 1 ELSE SUM(ISNULL(T2.CA_COMP_PROD,0)) END) )) )'IM_TOTA',                                        

T1.FE_DOCU, CO_PROD,          

       ( SUM(ISNULL(T2.CA_COMP_PROD,0)*ISNULL(IM_COST_PROM,0))/ ( CASE WHEN SUM(ISNULL(T2.CA_COMP_PROD,0))  =0 THEN 1 ELSE SUM(ISNULL(T2.CA_COMP_PROD,0)) END) )'IM_COST_PROM'          

INTO #TMCOMPRA                           

FROM TCMOVI_ALMA T1 WITH (NOLOCK)           

INNER JOIN TDMOVI_ALMA T2 WITH (NOLOCK)                                    

ON T1.CO_TDOC = T2.CO_TDOC                                             

AND T1.CO_SERI = T2.CO_SERI                                             

AND T1.NU_DOCU = T2.NU_DOCU                                             

WHERE T1.FE_DOCU =  @FE_TURN            

AND T1.CO_PROV IS NOT NULL  AND                                    

T1.CO_TDOC != '18'                               

GROUP BY T2.CO_PROD, T1.FE_DOCU          

ORDER BY T2.CO_PROD                                 

          

          

IF OBJECT_ID('TEMPDB.DBO.#COMPRA_GALO') IS NOT NULL            

BEGIN          

       DROP TABLE #COMPRA_GALO                   

END          

        

SELECT           

       @VSNO_GRIF AS 'GRIFO', M.FE_DOCU 'FE_TURN',5 'TIPOREG', 'GALONES COMPRADO(GLN)' AS 'DSC',          

    ISNULL([101010],0) 'G84',          

    ISNULL([101020],0) 'G90',           

    ISNULL([101030],0) 'G95',          

    ISNULL([101040],0) 'G97',          

       ISNULL([101050],0) 'GD2',           

    ISNULL([101060],0) 'GD1',          

    ISNULL([101070],0) 'GLP',           

    ISNULL([310838],0) 'GNV',          

    ISNULL([101080],0) 'UR',          

       (ISNULL([101010],0) + ISNULL([101020],0) + ISNULL([101030],0) + ISNULL([101040],0) +          

        ISNULL([101050],0) + ISNULL([101060],0) + ISNULL([101070],0) + ISNULL([310838],0) +          

  ISNULL([101080],0)) 'TOTGLN',0 AS 'TOT'          

INTO #COMPRA_GALO          

FROM          

(            

       SELECT CA_COMP_PROD,FE_DOCU,CO_PROD          

       FROM #TMCOMPRA           

       WHERE FE_DOCU=@FE_TURN          

) AS P          

PIVOT          

(SUM(P.CA_COMP_PROD)          

FOR           

P.CO_PROD IN ( [101010], [101020],  [101070],[101050], [101030], [101040], [101060],[310838], [101080])          

) AS M          

          

IF OBJECT_ID('TEMPDB.DBO.#COMPRA_SOLES') IS NOT NULL            

BEGIN          

       DROP TABLE #COMPRA_SOLES                   

END          

          

SELECT           

       @VSNO_GRIF AS 'GRIFO', M.FE_DOCU 'FE_TURN',6 'TIPOREG', 'GALONES COMPRADO S/.'AS'DSC',          

    ISNULL([101010],0) 'G84',           

    ISNULL([101020],0) 'G90',          

    ISNULL([101030],0) 'G95',           

    ISNULL([101040],0) 'G97',          

       ISNULL([101050],0) 'GD2',          

    ISNULL([101060],0) 'GD1',           

    ISNULL([101070],0) 'GLP',           

    ISNULL([310838],0) 'GNV',          

    ISNULL([101080],0) 'UR',          

       (ISNULL([101010],0)+ISNULL([101020],0)+ ISNULL([101030],0)+ ISNULL([101040],0)+          

        ISNULL([101050],0)+ISNULL([101060],0)+ ISNULL([101070],0)+ISNULL([310838],0) +          

  ISNULL([101080],0)) 'TOTGLN',0 AS 'TOT'          

INTO #COMPRA_SOLES          

FROM          

(            

       SELECT           

     IM_TOTA,FE_DOCU,CO_PROD          

       FROM #TMCOMPRA           

       WHERE FE_DOCU=@FE_TURN          

)           

AS P          

PIVOT          

(SUM(P.IM_TOTA)          

FOR           

P.CO_PROD IN ( [101010], [101020],  [101070],[101050], [101030], [101040], [101060],[310838], [101080])          

) AS M          

          

---------------------------7          

SELECT           

       @VSNO_GRIF AS 'GRIFO',M.FE_TURN,7'TIPOREG','GALONES DESPACHADOS SEGÚN VARILLAJE'AS'DSC',          

    ISNULL([101010],0) 'G84',          

    ISNULL([101020],0) 'G90',           

       ISNULL([101030],0) 'G95',           

    ISNULL([101040],0) 'G97',          

       ISNULL([101050],0) 'GD2',           

    ISNULL([101060],0) 'GD1',          

    ISNULL([101070],0) 'GLP',           

    ISNULL([310838],0) 'GNV',          

    ISNULL([101080],0) 'UR',          

       (ISNULL([101010],0)+ISNULL([101020],0)+ ISNULL([101030],0)+ ISNULL([101040],0)+          

        ISNULL([101050],0)+ISNULL([101060],0)+ ISNULL([101070],0)+ISNULL([310838],0) +          

  ISNULL([101080],0)) 'TOTGLN',0 AS 'TOT'          

INTO #VARILLAJE_TURNO          

FROM          

(          

       SELECT           

     (ISNULL(T2.CA_MEDI,0)-ISNULL(T1.CA_MEDI,0)+ISNULL(T3.CA_COMP_PROD,0))'CA_MEDI',T1.FE_TURN,T2.CO_PROD,T1.CO_TURN          

       FROM #VARILLAJE T1           

       LEFT JOIN #VARILLAJE T2           

       ON T1.FE_TURN-1=T2.FE_TURN AND T1.CO_PROD=T2.CO_PROD          

LEFT JOIN #TMCOMPRA T3           

       ON T1.FE_TURN=T3.FE_DOCU AND T1.CO_PROD=T3.CO_PROD          

       WHERE T1.FE_TURN=@FE_TURN          

)           

AS P          

PIVOT          

(SUM(P.CA_MEDI)          

FOR           

P.CO_PROD IN ( [101010], [101020],  [101070],[101050], [101030], [101040], [101060],[310838], [101080])          

) AS M          

          

--------------------------------------8          

SELECT           

       @VSNO_GRIF AS 'GRIFO',M.FE_TURN,8 'TIPOREG','TOTAL DESPACHO VARILLAJE S/.'AS'DSC',          

    ISNULL([101010],0) 'G84',          

    ISNULL([101020],0) 'G90',           

    ISNULL([101030],0) 'G95',           

       ISNULL([101040],0) 'G97',          

    ISNULL([101050],0) 'GD2',           

    ISNULL([101060],0) 'GD1',           

    ISNULL([101070],0) 'GLP',           

    ISNULL([310838],0) 'GNV',          

    ISNULL([101080],0) 'UR',          

       (ISNULL([101010],0)+ISNULL([101020],0)+ ISNULL([101030],0)+ ISNULL([101040],0)+          

        ISNULL([101050],0)+ISNULL([101060],0)+ ISNULL([101070],0)+ ISNULL([101080],0) ) 'TOTGLN',          

       (ISNULL([101010],0)+ISNULL([101020],0)+ ISNULL([101030],0)+ ISNULL([101040],0)          

     +ISNULL([101050],0)+ISNULL([101060],0)+ ISNULL([101070],0)+ ISNULL([310838],0)          

  + ISNULL([101080],0)) AS 'TOT'           

INTO #VARILLAJE_TOTA_TURNO          

FROM          

(          

       SELECT           

     (case           

      when (T2.CO_PROD='101070' or T2.CO_PROD='310838' or T2.CO_PROD='101080') then           

               ISNULL((isnull(T2.CA_MEDI,0)+isnull(t5.CA_COMP_PROD,0)-isnull(T1.CA_MEDI,0)),0)*3.7853*ISNULL(T4.NU_PREC,0)           

     else          

     ISNULL((isnull(T2.CA_MEDI,0)+isnull(t5.CA_COMP_PROD,0)-isnull(T1.CA_MEDI,0)),0)*ISNULL(T4.NU_PREC,0) end)'CA_MEDI',          

     T1.FE_TURN,T2.CO_PROD,T1.CO_TURN          

       FROM #VARILLAJE T1          

       LEFT JOIN #VARILLAJE T2           

       ON T1.FE_TURN-1=T2.FE_TURN AND T1.CO_PROD=T2.CO_PROD           

       INNER JOIN           

       (           

     SELECT           

   T2.CO_PROD,ISNULL(T3.DE_PROD_CORT,'')  AS NO_PROD,           

   SUM((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) 'TO_GALN',            

   ( SUM(((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))*(ISNULL(T2.IM_PRE1,0)))          

   /(CASE WHEN SUM ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0))  =0 THEN 1           

   ELSE SUM ((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) END))  'NU_PREC',           

   SUM(((CASE WHEN T2.IM_LECF > 0 AND T2.IM_LECF < T2.IM_LECI AND T2.IM_LECI > 900000 THEN (1000000.0 - T2.IM_LECI) + T2.IM_LECF ELSE T2.IM_LECF - T2.IM_LECI END)-ISNULL(IM_CALI,0)) *(T2.IM_PRE1)) 'TOTSOL'
     FROM TCCONT T1 WITH(NOLOCK)           

     INNER JOIN TDCONT T2 WITH (NOLOCK)          

     ON T1.CO_CONT = T2.CO_CONT           

     INNER JOIN TMPROD T3 WITH(NOLOCK)          

     ON T2.CO_PROD = T3.CO_PROD          

     WHERE           

     T1.CO_EMPR = 1          

     AND T1.CO_ESTA = 1          

     AND T1.FE_TURN= '2014-10-01'          

     GROUP BY T2.CO_PROD, T3.DE_PROD_CORT            

       ) T4           

       ON T1.CO_PROD=T4.CO_PROD           

       LEFT JOIN #TMCOMPRA AS T5           

       ON T1.FE_TURN=T5.FE_DOCU AND T1.CO_PROD=T5.CO_PROD          

       WHERE T1.FE_TURN='2014-10-01'          

)          

AS P          

PIVOT          

(          

SUM(P.CA_MEDI)          

FOR           

P.CO_PROD IN ( [101010], [101020],  [101070],[101050], [101030], [101040], [101060],[310838],[101080])          

) AS M          

          

          

SELECT           

       T1.*,@FE_TURN'FE_TURN'           

INTO #DIFE_VARI          

FROM @TM_RESCONMECAFIN T1 --INNER JOIN           

WHERE T1.IDREG IN  (SELECT T2.IDREG FROM @TM_RESCONMECAFIN T2 WHERE T2.DESCR IN ( 'TOTAL VENTA SEGÚN SISTEMA GLN','TOTAL VENTA SEGÚN SISTEMA S/.'))          

          

IF OBJECT_ID('TEMPDB.DBO.#DIFE_VARI_SIST_CONTO') IS NOT NULL            

BEGIN          

       DROP TABLE #DIFE_VARI_SIST_CONTO          

END          

               

SELECT           

       T2.GRIFO,T2.FE_TURN,7 'TIPOREG','DIF. SISTEMA VS VARILLA GLN'AS 'DSC',          

       ISNULL(COMB1,0)-ISNULL(G84,0)'G84',          

       ISNULL(COMB2,0)-ISNULL(G90,0)'G90',          

       ISNULL(COMB3,0)-ISNULL(G95,0)'G95',          

       ISNULL(COMB4,0)-ISNULL(G97,0)'G97',          

       ISNULL(COMB5,0)-ISNULL(GD2,0)'GD2',          

       ISNULL(COMB6,0)-ISNULL(GD1,0)'GD1',          

       ISNULL(COMB7,0)-ISNULL(GLP,0)'GLP',          

       ISNULL(COMB8,0)-ISNULL(GNV,0)'GNV',          

    ISNULL(COMB9,0)-ISNULL(UR,0)'UR',          

       ISNULL(T1.TOTGL,0)-ISNULL(T2.TOTGLN,0)'TOTGLN',          

       ISNULL(T1.TOTSO,0)-ISNULL(T2.TOT,0)'TOT'          

INTO #DIFE_VARI_SIST_CONTO          

FROM #DIFE_VARI T1           

INNER JOIN           

(          

       SELECT           

     T1.GRIFO, T1.FE_TURN, T1.TIPOREG, T1.DSC,           

  T1.G84, T1.G90, T1.G95, T1.G97,          

     T1.GD2, T1.GD1, T1.GLP, T1.GNV, T1.UR,           

  T1.TOTGLN, ISNULL(T2.TOT,0)AS 'TOT'          

       FROM  #VARILLAJE_TURNO T1           

       INNER JOIN #VARILLAJE_TOTA_TURNO T2           

       ON T1.FE_TURN=T2.FE_TURN          

) AS T2           

ON T1.FE_TURN=T2.FE_TURN          

WHERE T1.DESCR IN ( 'TOTAL VENTA SEGÚN SISTEMA GLN')          

          

-------------------          

-------------------          

IF OBJECT_ID('TEMPDB.DBO.#VARILLA_GALONES') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLA_GALONES                

END          

          

SELECT           

       T1.GRIFO, T1.FE_TURN, T1.TIPOREG, T1.DSC,           

    (T1.G84 + T3.G84) 'G84',           

    (T1.G90 + T3.G90) 'G90',           

    (T1.G95 + T3.G95) 'G95',           

    (T1.G97 + T3.G97) 'G97',          

       (T1.GD2 + T3.GD2) 'GD2',           

    (T1.GD1 + T3.GD1)'GD1',           

    (T1.GLP + T3.GLP)'GLP',          

    (T1.GNV + T3.GNV)'GNV',           

    (T1.UR + T3.UR) 'UR',           

    (T1.TOTGLN+T3.TOTGLN)'TOTGLN',          

    ( ISNULL(T2.TOT,0)+ ISNULL(T4.TOT,0)) AS 'TOT'           

INTO #VARILLA_GALONES          

FROM  #VARILLAJE_TURNO T1           

INNER JOIN #VARILLAJE_TOTA_TURNO T2           

ON T1.FE_TURN=T2.FE_TURN           

LEFT JOIN  #COMPRA_GALO T3           

ON  T1.FE_TURN=T3.FE_TURN           

LEFT JOIN #COMPRA_SOLES T4           

ON  T3.FE_TURN=T4.FE_TURN          

          

IF OBJECT_ID('TEMPDB.DBO.#VARILLA_GALONES_SOLES') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLA_GALONES_SOLES               

END          

          

SELECT           

       T2.GRIFO, T2.FE_TURN, T2.TIPOREG, T2.DSC,           

    (T2.G84) 'G84',           

    (T2.G90) 'G90',           

    (T2.G95) 'G95',          

    (T2.G97) 'G97',          

       (T2.GD2) 'GD2',           

    (T2.GD1) 'GD1',          

    (T2.GLP) 'GLP',          

    (T2.GNV) 'GNV',          

    (T2.UR) 'UR',          

    (T1.TOTGLN+T3.TOTGLN)'TOTGLN',          

    ( ISNULL(T2.TOT,0))AS 'TOT'           

INTO #VARILLA_GALONES_SOLES          

FROM  #VARILLAJE_TURNO T1           

INNER JOIN #VARILLAJE_TOTA_TURNO T2           

ON T1.FE_TURN=T2.FE_TURN           

LEFT JOIN  #COMPRA_GALO T3           

ON  T1.FE_TURN=T3.FE_TURN           

LEFT JOIN #COMPRA_SOLES T4           

ON  T3.FE_TURN=T4.FE_TURN          

          

IF OBJECT_ID('TEMPDB.DBO.#VARILLA_GALONES_SOLES_FINA') IS NOT NULL            

BEGIN          

       DROP TABLE #VARILLA_GALONES_SOLES_FINA              

END          

-------------------------------------------------------          

SELECT           

       T2.GRIFO,T2.FE_TURN,9 'TIPOREG','DIF. SISTEMA VS VARILLA GLN'AS 'DSC',          

       ISNULL(COMB1,0) -ISNULL(G84,0)'G84',          

       ISNULL(COMB2,0) -ISNULL(G90,0)'G90',          

       ISNULL(COMB3,0) -ISNULL(G95,0)'G95',          

       ISNULL(COMB4,0) -ISNULL(G97,0)'G97',          

       ISNULL(COMB5,0) -ISNULL(GD2,0)'GD2',          

       ISNULL(COMB6,0) -ISNULL(GD1,0)'GD1',          

       ISNULL(COMB7,0) -ISNULL(GLP,0)'GLP',          

       ISNULL(COMB8,0) -ISNULL(GNV,0)'GNV',          

    ISNULL(COMB9,0) -ISNULL(UR,0)'UR',          

       ISNULL(T1.TOTGL,0)-ISNULL(T2.TOTGLN,0)'TOTGLN',          

       ISNULL(T1.TOTSO,0)-ISNULL(T2.TOT,0)'TOT'          

INTO #VARILLA_GALONES_SOLES_FINA          

FROM #DIFE_VARI T1           

INNER JOIN #VARILLA_GALONES T2           

ON T1.FE_TURN=T2.FE_TURN          

WHERE T1.DESCR IN ( 'TOTAL VENTA SEGÚN SISTEMA GLN')          

          

---------------------------------UNIONES           

SELECT           

       @VSNO_GRIF AS 'GRIFO',@FE_TURN FE_TURN, IDREGREP 'TIPOREG', DESCR 'DSC', COMB1 'G84',           

       COMB2 'G90', COMB3 'G95', COMB4 'G97', COMB5 'GD2', COMB6 'GD1', COMB7 'GLP',COMB8'GNV', COMB9'UR',          

       TOTGL 'TOTGLN', TOTSO 'TOT'           

FROM @TM_RESCONMECAFIN          

WHERE DESCR IS NOT NULL          

UNION ALL          

SELECT           

       T1.GRIFO, T1.FE_TURN, T1.TIPOREG, T1.DSC, (T1.G84)'G84', (T1.G90)'G90', (T1.G95)'G95', (T1.G97)'G97',          

       (T1.GD2)'GD2', (T1.GD1)'GD1', (T1.GLP)'GLP',(T1.GNV)'GNV', (T1.UR) 'UR',          

    (T1.TOTGLN)'TOTGLN',( ISNULL(T2.TOT,0))AS 'TOT'          

FROM  #VARILLAJE_TURNO T1           

INNER JOIN #VARILLAJE_TOTA_TURNO T2           

ON T1.FE_TURN=T2.FE_TURN           

UNION ALL          

SELECT           

       T2.GRIFO, T2.FE_TURN, T2.TIPOREG, T2.DSC, (T2.G84)'G84', (T2.G90)'G90', (T2.G95)'G95', (T2.G97)'G97',           

       (T2.GD2)'GD2', (T2.GD1)'GD1', (T2.GLP)'GLP',(T2.GNV)'GNV', (T2.UR)'UR', (T1.TOTGLN)'TOTGLN',( ISNULL(T2.TOT,0))AS 'TOT'          

FROM  #VARILLAJE_TURNO T1           

INNER JOIN #VARILLAJE_TOTA_TURNO T2           

ON T1.FE_TURN=T2.FE_TURN           

UNION ALL          

SELECT           

       GRIFO,FE_TURN,9 'TIPOREG','DIF. SISTEMA VS VARILLA GLN'AS 'DSC',          

       ISNULL(G84,0)'G84',          

       ISNULL(G90,0)'G90',          

       ISNULL(G95,0)'G95',          

       ISNULL(G97,0)'G97',          

       ISNULL(GD2,0)'GD2',          

       ISNULL(GD1,0)'GD1',          

       ISNULL(GLP,0)'GLP',          

       ISNULL(GNV,0)'GNV',          

    ISNULL(UR,0)'UR',          

       ISNULL(TOTGLN,0)'TOTGLN',          

       ISNULL(TOT,0)'TOT'          

FROM #DIFE_VARI_SIST_CONTO           

UNION ALL          

---------------------------------------------10          

SELECT           

       T2.GRIFO,T2.FE_TURN,9 'TIPOREG','DIF. SISTEMA VS VARILLA S/.'AS 'DSC',          

       ISNULL(COMB1,0)-ISNULL(T2.G84,0)'G84',          

       ISNULL(COMB2,0)-ISNULL(T2.G90,0)'G90',          

       ISNULL(COMB3,0)-ISNULL(T2.G95,0)'G95',          

       ISNULL(COMB4,0)-ISNULL(T2.G97,0)'G97',          

       ISNULL(COMB5,0)-ISNULL(T2.GD2,0)'GD2',          

       ISNULL(COMB6,0)-ISNULL(T2.GD1,0)'GD1',          

       ISNULL(COMB7,0)-ISNULL(T2.GLP,0)'GLP',          

       ISNULL(COMB8,0)-ISNULL(T2.GNV,0) 'GNV',          

    ISNULL(COMB9,0)-ISNULL(T2.UR,0) 'UR',          

       (T3.TOTGLN)AS 'TOTGLN',          

       (ISNULL(COMB1,0) - ISNULL(T2.G84,0) + ISNULL(COMB2,0) - ISNULL(T2.G90,0) + ISNULL(COMB3,0) - ISNULL(T2.G95,0) + ISNULL(COMB4,0)-  ISNULL(T2.G97,0) +          

        ISNULL(COMB5,0) - ISNULL(T2.GD2,0) + ISNULL(COMB6,0) - ISNULL(T2.GD1,0) + ISNULL(COMB7,0) - ISNULL(T2.GLP,0) + ISNULL(COMB8,0) - ISNULL(T2.GNV,0) +           

  ISNULL(COMB9,0) - ISNULL(T2.UR,0)          

    ) AS 'TOT'          

FROM #DIFE_VARI T1           

INNER JOIN #VARILLA_GALONES_SOLES T2            

ON T1.FE_TURN=T2.FE_TURN           

INNER JOIN #DIFE_VARI_SIST_CONTO T3           

ON T1.FE_TURN=T3.FE_TURN          

WHERE T1.DESCR IN ( 'TOTAL VENTA SEGÚN SISTEMA S/')          

UNION ALL           

----------------------------------------------5               

          

SELECT           

     T1.GRIFO, T1.FE_TURN, T1.TIPOREG, T1.DSC,           

  T1.G84, T1.G90, T1.G95, T1.G97, T1.GD2, T1.GD1, T1.GLP, T1.GNV, T1.UR, T1.TOTGLN, ISNULL(T1.TOT,0)AS 'TOT'           

FROM  #DESCUENTO T1           

          

drop table #TCDOCU_COMB
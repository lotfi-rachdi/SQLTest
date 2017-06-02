CREATE OR REPLACE PACKAGE BODY api_core.PCK_PERIOD
-- ***************************************************************************
--  PACKAGE     : PCK_PERIOD
--  DESCRIPTION : Package to deal with Period coming from web API
--                inspired from and reusing how XML files of types
--                T_PERIOD coming from PDAs are uploaded
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.20 | Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2016.02.15 | Hocine HAMMOU
--          | [10093] MODE DECONNECTE
--          | Modification de GetSitePeriods : prise en compte également des file_id de creation de période
--          | en attente et donc inconnu dans le BO
--          |
--  V01.101 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
--          |
-- ***************************************************************************
IS
c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_PERIOD_PDA.PERIOD_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := IMPORT_PDA.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API; -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_PERIOD';                                       -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                                            -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                                             -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_EVT_LINE_NUMBER              CONSTANT PLS_INTEGER  := 1;                                                -- IMPORT_PDA.T_PERIOD_IMPORTED.LINE_NBR initialisé à 1 car un seul evenement par fichier
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';                               --
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';
c_LINE_STATE_TO_BE_PROCESSED   CONSTANT NUMBER(1)    := 0 ;                                               -- IMPORT_PDA.T_PERIOD_IMPORTED.LINE_STATE = 0 : Statut A TRAITER


-- record and list to store the period id
-- TYPE period_id_type IS RECORD
--    ( period_id     MASTER.PERIOD.PERIOD_ID%TYPE
--     ,pda_period_id MASTER.PERIOD.PDA_PERIOD_ID%TYPE
--    );
-- TYPE tab_period_id_type IS TABLE OF period_id_type;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de Period
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_FILE_PDA_ID  IN VARCHAR2     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_DTM_UTC IN DATE         --ENTRY_FILE.LOCAL_DTM%TYPE)
                 , p_FILE_ID      IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
BEGIN

  l_file_name :=                           c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || c_FILE_STATUS_BUILD
               || c_FILE_NAME_SEPARATOR || c_FILE_VERSION
               || c_FILE_NAME_SEPARATOR || 'UTC' || to_char(p_FILE_DTM_UTC,c_FILE_DTM_MASK)
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;


-- -- ---------------------------------------------------------------------------
-- -- DESCRIPTION : Check Period Overlap
-- -- ---------------------------------------------------------------------------
-- --  PARAMETER IN  :
-- --  PARAMETER OUT :
-- -- ---------------------------------------------------------------------------
-- FUNCTION CheckPeriodOverlap(p_site_id IN MASTER.SITE.SITE_ID%TYPE, p_START_DATE_RANGE IN MASTER.PERIOD.DATE_FROM%TYPE, p_END_DATE_RANGE IN MASTER.PERIOD.DATE_TO%TYPE ) RETURN tab_period_id_type
-- IS
--    l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'CheckPeriodOverlap';
--    l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
--    l_result tab_period_id_type;
--    l_tab_period_id tab_period_id_type;
--    l_START_DATE_RANGE DATE;
--    l_END_DATE_RANGE DATE;
-- BEGIN
--    l_result := new tab_period_id_type();
--    l_START_DATE_RANGE := TRUNC(p_START_DATE_RANGE);
--    l_END_DATE_RANGE   := TRUNC(p_END_DATE_RANGE);
--    SELECT p.PERIOD_ID, p.PDA_PERIOD_ID
--    BULK COLLECT INTO l_result
--    FROM MASTER.PERIOD p
--    WHERE p.SITE_ID = p_site_id
--    AND (
--           (l_START_DATE_RANGE BETWEEN p.DATE_FROM AND p.DATE_TO )
--            OR
--           (l_END_DATE_RANGE   BETWEEN p.DATE_FROM AND p.DATE_TO )
--            OR
--           (p.DATE_FROM        BETWEEN l_START_DATE_RANGE AND l_END_DATE_RANGE )
--            OR
--           (p.DATE_TO          BETWEEN l_START_DATE_RANGE AND l_END_DATE_RANGE )
--           )
--    ORDER BY p.PERIOD_ID
--    ;
--    RETURN l_result;
-- EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--       NULL;
--    WHEN OTHERS THEN
--       MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
--       RAISE;
-- END CheckPeriodOverlap;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for period
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_PERIOD_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  TRT_PERIOD( p_period IN api_core.PERIOD_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'TRT_PERIOD';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_period_file_name    IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id          IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_site_id             MASTER.SITE.SITE_ID%TYPE;
   l_file_state          NUMBER(1);
   l_SiteTestTypeId      SITE.TEST_TYPE_ID%TYPE;
   l_timezone            MASTER.SITE.TIMEZONE%TYPE;      -- 2017.01.20 projet [10237]
BEGIN

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_period.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_period.INTERNATIONAL_SITE_ID);
   END IF;

   -- -----------------------------------------------------------------------------
   -- RECUPERATION DE LA TIMEZONE DU PUDO
   -- -----------------------------------------------------------------------------
   l_timezone := MASTER_PROC.PCK_SITE.GetSiteTimezone(p_siteid => l_site_id);

   -- -----------------------------------------------------------------------------
   -- CONTROLE SI VRAI PUDO (PAS FORMATION, PAS TRAINING
   -- -----------------------------------------------------------------------------
   l_SiteTestTypeId:= PCK_SITE.SiteTestTypeId( p_site_id => l_site_id );
   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN
      l_file_state := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   ELSE
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_site_type_id,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||p_period.INTERNATIONAL_SITE_ID||').');
   END IF;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_period_file_name := filename( p_FILE_PDA_ID => p_period.INTERNATIONAL_SITE_ID, p_FILE_DTM_UTC => l_start_date_UTC, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_period_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => c_FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_period.INTERNATIONAL_SITE_ID
                                    , p_file_dtm        => p_period.LAST_UPDATE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_PERIOD_IMPORTED
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_PERIOD_IMPORTED.InsertPeriodImported( p_file_id            => l_filexml_id
                                                      , p_line_nbr           => c_EVT_LINE_NUMBER
                                                      , p_bo_period_id       => p_period.BO_PERIOD_ID
                                                      , p_pda_period_id      => p_period.PDA_PERIOD_ID
                                                      , p_start_dtm          => trunc(p_period.START_DTM)
                                                      , p_end_dtm            => trunc(p_period.END_DTM)
                                                      , p_period_type        => p_period.PERIOD_TYPE_ID
                                                      , p_last_update_dtm    => ( FROM_TZ(CAST(p_period.LAST_UPDATE_DTM AS TIMESTAMP ) , PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ) ) AT TIME ZONE l_timezone -- 2017.01.20 projet [10237] integration date dans la time zone du pudo
                                                      , p_deleted_dtm        => ( FROM_TZ(CAST(p_period.DELETED_DTM AS TIMESTAMP ) , PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ) ) AT TIME ZONE l_timezone -- 2017.01.20 projet [10237] integration date dans la time zone du pudo
                                                      );


   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END TRT_PERIOD;


-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_period      --> information about period
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit                MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_PERIOD';
   l_start_date          MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams      VARCHAR2(4000);
   l_relevant_properties VARCHAR2(4000);
   --l_site_id             MASTER.SITE.SITE_ID%TYPE;
   --l_tab_period_id       tab_period_id_type;
   l_sysdate             DATE := TRUNC(SYSDATE);
BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_period.CheckMsgCreatePeriod(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   --l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_period.INTERNATIONAL_SITE_ID );

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI DATE DE DEBUT ANTERIEURE A LA DATE DU JOUR
  -- -----------------------------------------------------------------------------
   IF  p_period.START_DTM < l_sysdate THEN
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_invalid_range_date,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_invalid_range_date||'(START DATE:'||p_period.START_DTM || '-END DATE:'||p_period.END_DTM||').');
   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI DATE DE DEBUT POSTERIEURE A LA DATE DE FIN
  -- -----------------------------------------------------------------------------
   IF  p_period.START_DTM > p_period.END_DTM THEN
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_invalid_range_date,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_invalid_range_date||'(START DATE:'||p_period.START_DTM || '-END DATE:'||p_period.END_DTM||').');
   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI OVERLAP DE PERIOD
  -- SI FONCTION RETOURNE > 0 ALORS EXISTENCE DE PERIOD OVERLAP
  -- -----------------------------------------------------------------------------
  --    l_tab_period_id := new tab_period_id_type();
  --    l_tab_period_id := CheckPeriodOverlap(p_site_id => l_site_id, p_START_DATE_RANGE => p_period.START_DTM, p_END_DATE_RANGE => p_period.END_DTM);
  --    IF l_tab_period_id.COUNT > 0 THEN
  --       RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_period_overlapping,'[API_CORE] PERIOD OVERLAPPING (START_DTM:' || p_period.START_DTM ||'-p_period.END_DTM:' || p_period.END_DTM ||  ').');
  --    END IF;

   -- ------------------------------------------------------------------------
   -- call trt_PERIOD FUNCTION to continue the PERIOD treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= trt_PERIOD ( p_period   => p_period );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PERIOD CREATED (INTERNATIONAL_SITE_ID:'|| p_period.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_PERIOD;


-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_period      --> information about period
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE del_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'del_PERIOD';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_period.CheckMsgDeletePeriod(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

  -- ------------------------------------------------------------------------
   -- call trt_PERIOD FUNCTION to continue the PERIOD treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= trt_PERIOD ( p_period   => p_period );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PERIOD DELETED (INTERNATIONAL_SITE_ID:'|| p_period.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END del_PERIOD;



-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_period      --> information about period
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE upd_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'upd_PERIOD';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
   --l_site_id             MASTER.SITE.SITE_ID%TYPE;
   --l_tab_period_id       tab_period_id_type;
BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_period.CheckMsgUpdatePeriod(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   --l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_period.INTERNATIONAL_SITE_ID );

   -- Validation du Message
   IF  p_period.START_DTM > p_period.END_DTM THEN
      -- ?? QUE FAIT-ON ? Le traitement doit-il continuer ? ou doit-ont faire un RAISE
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_invalid_range_date,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_invalid_range_date||'(START DATE:'||p_period.START_DTM || '-END DATE:'||p_period.END_DTM||').');
   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI OVERLAP DE PERIOD
  -- SI FONCTION RETOURNE > 0 ALORS EXISTENCE DE PERIOD OVERLAP
  -- -----------------------------------------------------------------------------
  --    l_tab_period_id := CheckPeriodOverlap(p_site_id => l_site_id, p_START_DATE_RANGE => p_period.START_DTM, p_END_DATE_RANGE => p_period.END_DTM);
  --    IF l_tab_period_id.COUNT > 0 THEN
  --      FOR I in l_tab_period_id.FIRST .. l_tab_period_id.LAST
  --      LOOP
  --         IF l_tab_period_id(i).period_id <> p_period.BO_PERIOD_ID AND l_tab_period_id(i).pda_period_id <> p_period.PDA_PERIOD_ID THEN --2016.01.13
  --            RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_period_overlapping,'[API_CORE] UPDATE PERIOD RAISE AN OVERLAPPING');
  --         END IF;
  --      END LOOP;
  --    END IF;

  -- ------------------------------------------------------------------------
   -- call trt_PERIOD FUNCTION to continue the PERIOD treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= trt_PERIOD ( p_period => p_period );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PERIOD UPDATED (INTERNATIONAL_SITE_ID:'|| p_period.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END upd_PERIOD;


-------------------------------------------------------------------
-- Cette fonction doit être externalisée ?? dans PCK_SITE ???
---------------------------------------------------------------
FUNCTION GetSitePeriods(p_international_site_id MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE,
                        p_site_id     MASTER.PERIOD.SITE_ID%TYPE,
                        p_date_start  DATE,
                        p_date_end    DATE,
                        p_type_period MASTER.PERIOD.PERIOD_TYPE_ID%TYPE)
   RETURN api_core.TAB_PERIOD_TYPE
IS
   l_TAB_PERIOD_TYPE     api_core.TAB_PERIOD_TYPE;
   l_tab_period_file_id  IMPORT_PDA.PCK_PERIOD_IMPORTED.TAB_ELEMENT_NUMBER_TYPE;
BEGIN
   l_TAB_PERIOD_TYPE := api_core.TAB_PERIOD_TYPE(); -- initialisation du tableau

   WITH periods_rows AS
   (
   SELECT  p_international_site_id                         INTERNATIONAL_SITE_ID
          ,p.PERIOD_ID                                     BO_PERIOD_ID
          ,p.PDA_PERIOD_ID                                 PDA_PERIOD_ID
          ,p.DATE_FROM                                     START_DTM
          ,p.DATE_TO                                       END_DTM
          ,TO_NUMBER(p.PERIOD_TYPE_ID)                     PERIOD_TYPE_ID
          ,NVL( p.LAST_UPDATE_DTM AT TIME ZONE 'UTC' , p.CREATION_DTM) AS LAST_UPDATE_DTM -- 2017.01.20 Projet [10237]
          ,DECODE(p.deleted,NULL,TO_DATE(NULL,'yyyy-mm-dd hh24:mi:ss'), p.LAST_UPDATE_DTM AT TIME ZONE 'UTC' ) DELETED_DTM -- 2017.01.20 Projet [10237]
          ,NULL                                            TAB_PERIOD_FILE_ID
   FROM MASTER.PERIOD p
   WHERE p.SITE_ID = p_site_id
   AND (
          (p.DATE_FROM BETWEEN p_date_start AND p_date_end)
           OR
          (p.DATE_TO BETWEEN p_date_start AND p_date_end)
          )
   AND p.PERIOD_TYPE_ID = p_type_period
   UNION
   SELECT     p_international_site_id                                                      INTERNATIONAL_SITE_ID
             ,NULL                                                                         BO_PERIOD_ID
             ,p.PDA_PERIOD_ID                                                              PDA_PERIOD_ID
             ,p.START_DTM                                                                  START_DTM
             ,p.END_DTM                                                                    END_DTM
             ,TO_NUMBER(p.PERIOD_TYPE)                                                     PERIOD_TYPE_ID
             ,(p.LAST_UPDATE_DTM AT TIME ZONE 'UTC') LAST_UPDATE_DTM -- 2017.01.20 Projet [10237]
             ,(p.DELETED_DTM AT TIME ZONE 'UTC')     DELETED_DTM -- 2017.01.20 Projet [10237]
             ,p.FILE_ID                                                                    TAB_PERIOD_FILE_ID
   FROM IMPORT_PDA.T_PERIOD_IMPORTED p
   INNER JOIN IMPORT_PDA.T_XMLFILES x ON p.FILE_ID = x.FILE_ID
   WHERE x.FILE_PDA_ID = p_international_site_id
   AND x.FILE_STATE = IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML
   AND x.FILE_TYPE = api_core.PCK_API_CONSTANTS.c_PERIOD_XMLFILE
   AND p.LINE_STATE = c_LINE_STATE_TO_BE_PROCESSED
   AND p.BO_PERIOD_ID IS NULL
   AND (
          (p.START_DTM BETWEEN p_date_start AND p_date_end)
           OR
          (p.END_DTM BETWEEN p_date_start AND p_date_end)
          )
       AND p.PERIOD_TYPE = p_type_period
       )
   SELECT PERIOD_TYPE(
                      INTERNATIONAL_SITE_ID
                      , BO_PERIOD_ID
                      , PDA_PERIOD_ID
                      , START_DTM
                      , END_DTM
                      , PERIOD_TYPE_ID
                      , LAST_UPDATE_DTM
                      , DELETED_DTM
                      , TAB_ELEMENT_NUMBER_TYPE(TAB_PERIOD_FILE_ID)
                      )
    BULK COLLECT INTO l_TAB_PERIOD_TYPE
    FROM periods_rows
   ;

   IF l_TAB_PERIOD_TYPE IS NOT NULL THEN
      IF l_TAB_PERIOD_TYPE.COUNT > 0 THEN
         FOR i IN l_TAB_PERIOD_TYPE.FIRST .. l_TAB_PERIOD_TYPE.LAST
         LOOP
            IF l_TAB_PERIOD_TYPE(i).BO_PERIOD_ID IS NOT NULL THEN
                  IMPORT_PDA.PCK_PERIOD_IMPORTED.GetUnprocessedPeriodFileID( p_INTERNATIONAL_SITE_ID => p_international_site_id, p_PERIOD_ID => l_TAB_PERIOD_TYPE(i).BO_PERIOD_ID, p_tab_period_file_id => l_tab_period_file_id );
                  IF l_tab_period_file_id IS NOT NULL THEN
                     IF l_tab_period_file_id.COUNT > 0 THEN
                        l_TAB_PERIOD_TYPE(i).TAB_PERIOD_FILE_ID := NEW api_core.TAB_ELEMENT_NUMBER_TYPE();
                        l_TAB_PERIOD_TYPE(i).TAB_PERIOD_FILE_ID.EXTEND(l_tab_period_file_id.COUNT);
                        FOR j IN l_tab_period_file_id.FIRST .. l_tab_period_file_id.LAST
                        LOOP
                           l_TAB_PERIOD_TYPE(i).TAB_PERIOD_FILE_ID(j) := l_tab_period_file_id(j);
                        END LOOP;
                     END IF;
                  END IF;
            END IF;
         END LOOP;
      END IF;
   END IF;



  RETURN l_TAB_PERIOD_TYPE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END GetSitePeriods;


PROCEDURE GetSitePeriods( p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_START_DATE_RANGE IN OUT DATE, p_END_DATE_RANGE IN OUT DATE, p_period_tab OUT NOCOPY api_core.TAB_PERIOD_TYPE)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSitePeriods';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_site_id MASTER.SITE.SITE_ID%TYPE;

BEGIN

   -- -----------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS EN ENTREE
   -- -----------------------------------------------------------------------------
   IF TRIM(p_INTERNATIONAL_SITE_ID) IS NULL THEN -- champ obligatoire
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || 'INTERNATIONAL_SITE_ID');
   END IF;

   IF p_START_DATE_RANGE IS NULL THEN -- si date de debut plage non renseignée ??? alors on met la date au 1er jour du mois en cours( à déterminer, à valider ) ???
      p_START_DATE_RANGE := to_date( to_char(sysdate,'YYYYMM')||'01000000' , 'YYYYMMDDHH24MISS') ;
   END IF;

   IF p_END_DATE_RANGE IS NULL THEN -- si date de fin plage non renseignée ??? alors on met la date du jour + 12 MOIS ( à déterminer, à valider )???
      p_END_DATE_RANGE:= ADD_MONTHS(p_START_DATE_RANGE,12); -- sysdate + 12 mois ;
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_INTERNATIONAL_SITE_ID);
   END IF;

   -- ------------------------------------------------------------------------
   -- call trt_PERIOD FUNCTION to continue the PERIOD treatment
   -- ------------------------------------------------------------------------
   p_period_tab := TAB_PERIOD_TYPE(); -- initialisation du tableau

   p_period_tab := GetSitePeriods( p_international_site_id => p_international_site_id
                                  ,p_site_id               => l_site_id
                                  ,p_date_start            => p_START_DATE_RANGE
                                  ,p_date_end              => p_END_DATE_RANGE
                                  ,p_type_period           => PCK_API_CONSTANTS.c_Type_Period_VACATION  -- todo à modifier
                                  );


   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] GET PERIODS (INTERNATIONAL_SITE_ID:'|| p_INTERNATIONAL_SITE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSitePeriods;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de period
--               de façon proche à comme le ferait le process_all
--               en asynchron (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_period( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_period';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF p_FILE_ID IS NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || p_FILE_ID);
   END IF;

   IMPORT_PDA.PROCESS_XMLFILE_STEP2( p_xmlfile_id  => p_FILE_ID, p_action => c_JOB_ACTION);

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE]  JOB LAUNCHED (FILE_ID:'||  p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END process_xmlfile_period;


END PCK_PERIOD;

/
CREATE OR REPLACE PACKAGE BODY api_core.PCK_PERIOD_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_PERIOD_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers PERIOD
--                envoyés par le PDA via les WEB API
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
--          |
--  V01.001 | 2016.08.23 | Hocine HAMMOU
--          | TASK#59398 Suppression du contrôle fait sur le TEST_TYPE_ID du SITE
--          |
--  V01.002 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
--          |
-- ***************************************************************************
IS
c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_PERIOD_PDA.PERIOD_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'PDA';                       -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_PERIOD';                  -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                        -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';          --
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';

-- record and list to store the period id
TYPE period_id_type IS RECORD
   ( period_id     MASTER.PERIOD.PERIOD_ID%TYPE
    ,pda_period_id MASTER.PERIOD.PDA_PERIOD_ID%TYPE
   );
TYPE tab_period_id_type IS TABLE OF period_id_type;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de Period
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_period_pda   IN PDA_PERIOD_TYPE --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_ID      IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
BEGIN

  l_file_name :=  c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_period_pda.FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || p_period_pda.FILE_PDA_BUILD
               || c_FILE_NAME_SEPARATOR || p_period_pda.FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_period_pda.FILE_DTM,c_FILE_DTM_MASK)
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Check Period Overlap
-- ---------------------------------------------------------------------------
--  PARAMETER IN  :
--  PARAMETER OUT :
-- ---------------------------------------------------------------------------
FUNCTION CheckPeriodOverlap(p_site_id IN MASTER.SITE.SITE_ID%TYPE, p_START_DATE_RANGE IN MASTER.PERIOD.DATE_FROM%TYPE, p_END_DATE_RANGE IN MASTER.PERIOD.DATE_TO%TYPE ) RETURN tab_period_id_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'CheckPeriodOverlap';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result tab_period_id_type;
   l_START_DATE_RANGE DATE;
   l_END_DATE_RANGE DATE;
BEGIN
   l_result := new tab_period_id_type();
   l_START_DATE_RANGE := TRUNC(p_START_DATE_RANGE);
   l_END_DATE_RANGE   := TRUNC(p_END_DATE_RANGE);
   SELECT p.PERIOD_ID, p.PDA_PERIOD_ID
   BULK COLLECT INTO l_result
   FROM MASTER.PERIOD p
   WHERE p.SITE_ID = p_site_id
   AND (
          (l_START_DATE_RANGE BETWEEN p.DATE_FROM AND p.DATE_TO )
           OR
          (l_END_DATE_RANGE   BETWEEN p.DATE_FROM AND p.DATE_TO )
           OR
          (p.DATE_FROM        BETWEEN l_START_DATE_RANGE AND l_END_DATE_RANGE )
           OR
          (p.DATE_TO          BETWEEN l_START_DATE_RANGE AND l_END_DATE_RANGE )
          )
   ORDER BY p.PERIOD_ID
   ;
   RETURN l_result;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END CheckPeriodOverlap;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for period
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_PERIOD_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  PROCESS_PERIOD( p_period_pda IN api_core.PDA_PERIOD_TYPE ) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_PERIOD';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_period_file_name    IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id          IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_file_state          NUMBER(1) := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   l_site_timezone       MASTER.SITE.TIMEZONE%TYPE;
BEGIN

   -------------------------------------------------------------------------------
   --    RECUPERATION DE LA TIMEZONE DU PDA -- [10237] -- 2017.01.20
   -------------------------------------------------------------------------------
   l_site_timezone := MASTER_PROC.PCK_SITE.GetPDATimezone(p_pda_id => p_period_pda.FILE_PDA_ID);

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_period_file_name := filename( p_period_pda => p_period_pda, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_period_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => p_period_pda.FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_period_pda.FILE_PDA_ID
                                    , p_file_dtm        => NVL(p_period_pda.FILE_DTM,l_start_date_UTC) -- p_period_pda.LAST_UPDATE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_PERIOD_IMPORTED
   -- ------------------------------------------------------------------------
   IF p_period_pda.TAB_PDA_PERIOD IS NOT NULL THEN
      IF p_period_pda.TAB_PDA_PERIOD.COUNT > 0 THEN
         FOR i IN p_period_pda.TAB_PDA_PERIOD.FIRST .. p_period_pda.TAB_PDA_PERIOD.LAST
         LOOP
            IMPORT_PDA.PCK_PERIOD_IMPORTED.InsertPeriodImported( p_file_id            => l_filexml_id
                                                               , p_line_nbr           => i
                                                               , p_bo_period_id       => p_period_pda.TAB_PDA_PERIOD(i).BO_PERIOD_ID
                                                               , p_pda_period_id      => p_period_pda.TAB_PDA_PERIOD(i).PDA_PERIOD_ID
                                                               , p_start_dtm          => trunc(p_period_pda.TAB_PDA_PERIOD(i).START_DTM)
                                                               , p_end_dtm            => trunc(p_period_pda.TAB_PDA_PERIOD(i).END_DTM)
                                                               , p_period_type        => p_period_pda.TAB_PDA_PERIOD(i).PERIOD_TYPE_ID
                                                               , p_last_update_dtm    => FROM_TZ(CAST(p_period_pda.TAB_PDA_PERIOD(i).LAST_UPDATE_DTM AS TIMESTAMP ) , l_site_timezone ) -- 2017.01.20 projet [10237] integration date dans la timezone du pudo
                                                               , p_deleted_dtm        => FROM_TZ(CAST(p_period_pda.TAB_PDA_PERIOD(i).DELETED_DTM AS TIMESTAMP ) , l_site_timezone ) -- 2017.01.20 projet [10237] integration date dans la timezone du pudo
                                                               );



         END LOOP;
      END IF;
   END IF;

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END PROCESS_PERIOD;

-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_period_pda      --> information about period
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE SET_PERIOD( p_period_pda IN api_core.PDA_PERIOD_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit                MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SET_PERIOD';
   l_start_date          MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams      VARCHAR2(4000);
   l_relevant_properties VARCHAR2(4000);
   --l_site_id             MASTER.SITE.SITE_ID%TYPE;
   --l_tab_period_id       tab_period_id_type;
   --l_sysdate             DATE := TRUNC(SYSDATE);
BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_period_pda.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   IF p_period_pda.TAB_PDA_PERIOD IS NOT NULL THEN
      -- on vérifie le tableau contient des périodes, sinon on raise une error ???
      IF p_period_pda.TAB_PDA_PERIOD.COUNT = 0 THEN
         RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
      END IF;

      -- -- ----------------------------------
      -- -- SI OK on insère ou bien non ???
      -- -- ----------------------------------
      p_FILE_ID := PROCESS_PERIOD( p_period_pda => p_period_pda );

   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI DATE DE DEBUT ANTERIEURE A LA DATE DU JOUR
  -- -----------------------------------------------------------------------------
  -- IF  p_period_pda.START_DTM < l_sysdate THEN
  --    RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_invalid_range_date,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_invalid_range_date||'(START DATE:'||p_period_pda.START_DTM || '-END DATE:'||p_period_pda.END_DTM||').');
  -- END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI DATE DE DEBUT POSTERIEURE A LA DATE DE FIN
  -- -----------------------------------------------------------------------------
  --  IF  p_period_pda.START_DTM > p_period_pda.END_DTM THEN
  --     RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_invalid_range_date,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_invalid_range_date||'(START DATE:'||p_period_pda.START_DTM || '-END DATE:'||p_period_pda.END_DTM||').');
  --  END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI OVERLAP DE PERIOD
  -- SI FONCTION RETOURNE > 0 ALORS EXISTENCE DE PERIOD OVERLAP
  -- -----------------------------------------------------------------------------
  --    l_tab_period_id := new tab_period_id_type();
  --    l_tab_period_id := CheckPeriodOverlap(p_site_id => l_site_id, p_START_DATE_RANGE => p_period_pda.START_DTM, p_END_DATE_RANGE => p_period_pda.END_DTM);
  --    IF l_tab_period_id.COUNT > 0 THEN
  --       RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_period_overlapping,'[API_CORE] PERIOD OVERLAPPING (START_DTM:' || p_period_pda.START_DTM ||'-p_period_pda.END_DTM:' || p_period_pda.END_DTM ||  ').');
  --    END IF;


   -- ------------------------------------------------------------------------
   -- call trt_PERIOD FUNCTION to continue the PERIOD treatment
   -- ------------------------------------------------------------------------
   -- p_FILE_ID:= trt_PERIOD ( p_period_pda   => p_period_pda );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PERIOD CREATED (PDA_ID:'|| p_period_pda.FILE_PDA_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SET_PERIOD;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de period
--               de faeon proche a comme le ferait le process_all
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

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] JOB LAUNCHED (FILE_ID:'||  p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END process_xmlfile_period;


END PCK_PERIOD_FOR_PDA;

/
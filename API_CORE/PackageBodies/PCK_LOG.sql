CREATE OR REPLACE PACKAGE BODY api_core.PCK_LOG
-- ***************************************************************************
--  PACKAGE     : PCK_LOG
--  DESCRIPTION : Package pour gérer la log envoyé par les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.07.05 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
IS

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_LOG_PDA.LOG_PDA_V1';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := import_pda.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API;
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'LOG';
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.txt';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';
c_TIMESTAMP_TIME_ZONE          CONSTANT VARCHAR2(50) := 'Europe/Paris';


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de LOG
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- LOG-PDA-QA8SWANMI41567-PHOENIX 3.14.2 WM-1.0-20160624104119.txt
-- ---------------------------------------------------------------------------
FUNCTION filename( p_FILE_PDA_ID  IN VARCHAR2     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_DTM_UTC IN DATE         --ENTRY_FILE.LOCAL_DTM%TYPE)
                 , p_FILE_ID      IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit       master_proc.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date master_proc.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  import_pda.T_FILE_INFO.FILE_NAME%TYPE;
BEGIN

  l_file_name :=                           c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || c_FILE_STATUS_BUILD
               || c_FILE_NAME_SEPARATOR || c_FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_DTM_UTC,c_FILE_DTM_MASK)
               --|| c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      master_proc.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for log
--               then it will insert into IMPORT_PDA.T_FILE_INFO AND IMPORT_PDA.T_FILE_DETAIL
--
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------

FUNCTION PROCESS_LOG( p_log IN api_core.LOG_TYPE ) RETURN INTEGER -- return p_FILE_ID
IS
   l_unit                  master_proc.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_LOG';
   l_start_date            master_proc.PROC_LOG.START_TIME%TYPE := systimestamp;
-- l_trace                 VARCHAR2(32000);
   l_start_date_UTC        DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_file_id               import_pda.T_FILE_INFO.FILE_ID%TYPE := null;
   l_site_id               MASTER.SITE.SITE_ID%TYPE;
   l_file_state            NUMBER(1);
   l_SiteTestTypeId        SITE.TEST_TYPE_ID%TYPE;
   l_file_name             import_pda.T_FILE_INFO.FILE_NAME%TYPE;
BEGIN

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := master_proc.PCK_SITE.GetSiteid( p_site_international_id => p_log.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_log.INTERNATIONAL_SITE_ID);
   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI VRAI PUDO (PAS FORMATION, PAS TRAINING
  -- -----------------------------------------------------------------------------
   l_SiteTestTypeId:= PCK_SITE.SiteTestTypeId( p_site_id => l_site_id );
   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN
      l_file_state := import_pda.PCK_FILE.c_FILE_STATE_EXTRACTED;
   ELSE
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_site_type_id,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'|| p_log.INTERNATIONAL_SITE_ID ||').');
   END IF;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_file_id := import_pda.PCK_FILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_file_name := filename( p_FILE_PDA_ID => p_log.INTERNATIONAL_SITE_ID, p_FILE_DTM_UTC => p_log.LOCAL_DTM, p_file_id => l_file_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_FILE_INFO with file info header
   -- ------------------------------------------------------------------------
   import_pda.PCK_FILE.InsertFileInfo( p_file_id         => l_file_id
                                     , p_file_name       => l_file_name
                                     , p_file_dtm        => p_log.LOCAL_DTM
                                     , p_file_type       => c_FILE_TYPE
                                     , p_file_version    => c_FILE_VERSION
                                     , p_file_sender     => c_FILE_SENDER
                                     , p_file_pda_id     => p_log.INTERNATIONAL_SITE_ID
                                     , p_file_state      => l_file_state
                                     , p_file_state_dtm  => l_start_date
                                     , p_creation_dtm    => l_start_date
                                     , p_status_build    => c_FILE_STATUS_BUILD
                                     );


   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_FILE_DETAIL
   -- ------------------------------------------------------------------------
   IF p_log.TAB_LINES_LOG IS NOT NULL THEN
      FOR i In p_log.TAB_LINES_LOG.FIRST .. p_log.TAB_LINES_LOG.LAST
      LOOP
         import_pda.PCK_FILE.InsertFileDetail( p_file_id          => l_file_id
                                             , p_line_nbr         => i
                                             , p_line_content     => p_log.TAB_LINES_LOG(i)
                                             , p_line_state       => import_pda.PCK_FILE.c_LINE_STATE_EXTRACTED
                                             , p_line_state_dtm   => l_start_date
                                             );
      END LOOP;
 	END IF;

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_file_id;

EXCEPTION
   WHEN OTHERS THEN
      master_proc.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END PROCESS_LOG;



-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_log        --> information about logs
--  PARAMETER OUT : p_FILE_ID       --> file_id from IMPORT_PDA.T_FILE_INFO
-- ---------------------------------------------------------------------------

PROCEDURE SetLog( p_log IN api_core.LOG_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit                  master_proc.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetLog';
   l_start_date            master_proc.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams        VARCHAR2(4000);
   l_relevant_properties   VARCHAR2(4000);

BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_log.MissingMandatoryAttributes();
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- call PROCESS_LOG FUNCTION to continue treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= PROCESS_LOG( p_log => p_log);

   master_proc.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] LOG INSERTED (INTERNATIONAL_SITE_ID:'|| p_log.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      master_proc.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetLog;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement d'intégration des logs dans les tables métiers
--               comme le ferait le process_all, ici en asynchron (en background)
--
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_FILE_INFO.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_file_log( p_FILE_ID IN INTEGER )
IS l_unit master_proc.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_file_log';
   l_start_date  master_proc.PROC_LOG.START_TIME%TYPE := systimestamp;
-- l_trace VARCHAR2(32000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF p_FILE_ID IS NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || p_FILE_ID);
   END IF;

   import_pda.PROCESS_XMLFILE_STEP2( p_xmlfile_id  => p_FILE_ID, p_action => c_JOB_ACTION);

   master_proc.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE]  JOB LAUNCHED (FILE_ID:'||  p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      master_proc.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END process_file_log;


END PCK_LOG;


/
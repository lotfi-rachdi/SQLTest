CREATE OR REPLACE PACKAGE BODY api_core.PCK_CONFIG_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_CONFIG_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers CONFIG
--                envoyés par le PDA via les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
--          |
--  V01.001 | 2016.08.23 | Hocine HAMMOU
--          | TASK#59398 Suppression du contrôle fait sur le TEST_TYPE_ID du SITE
--          |
-- ***************************************************************************
IS

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_CONFIG_PDA.CONFIG_PDA_V2_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'PDA';                          -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_CONFIG';                    -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
--c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                          -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                           -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
--c_EVT_LINE_NUMBER              CONSTANT PLS_INTEGER  := 1;                              -- IMPORT_PDA.T_PERIOD_IMPORTED.LINE_NBR initialisé a 1 car un seul evenement par fichier
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';             --
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';
--c_TIMESTAMP_TIME_ZONE          CONSTANT VARCHAR2(50) := 'Europe/Paris';                 -- pour faire pareil que IMPORT_PDA.PCK_TRACING_PDA.TRACING_PDA_V1_STEP1
--c_LINE_STATE_TO_BE_PROCESSED   CONSTANT NUMBER(1)    := 0 ;                             -- IMPORT_PDA.T_PERIOD_IMPORTED.LINE_STATE = 0 : Statut A TRAITER



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de config
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_config_pda   IN PDA_CONFIG_TYPE
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
               || c_FILE_NAME_SEPARATOR || p_config_pda.FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || p_config_pda.FILE_PDA_BUILD
               || c_FILE_NAME_SEPARATOR || p_config_pda.FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_config_pda.FILE_DTM,c_FILE_DTM_MASK)
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for Config
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_CONFIG_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------

FUNCTION  PROCESS_CONFIG( p_config_pda IN api_core.PDA_CONFIG_TYPE ) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_CONFIG';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
--   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_config_file_name   IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id          IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_file_state          NUMBER(1) := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML ;

BEGIN

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_config_file_name := filename( p_config_pda => p_config_pda, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_config_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => p_config_pda.FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_config_pda.FILE_PDA_ID
                                    , p_file_dtm        => p_config_pda.FILE_DTM -- p_config_pda.LAST_UPDATE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_CONFIG_IMPORTED
   -- ------------------------------------------------------------------------
   IF p_config_pda.TAB_PDA_CONFIG IS NOT NULL THEN
      IF p_config_pda.TAB_PDA_CONFIG.COUNT > 0 THEN

         FOR i IN p_config_pda.TAB_PDA_CONFIG.FIRST .. p_config_pda.TAB_PDA_CONFIG.LAST
         LOOP
		 IMPORT_PDA.PCK_CONFIG_IMPORTED.InsertConfigImported( p_file_id         =>  l_filexml_id
                                                            , p_line_nbr        =>  i
                                                            , p_property_name   =>  p_config_pda.TAB_PDA_CONFIG(i).property_name
                                                            , p_property_value  =>  p_config_pda.TAB_PDA_CONFIG(i).property_value
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
END PROCESS_CONFIG;



-- ---------------------------------------------------------------------------
--  UNIT         : SetConfig
--  DESCRIPTION  : Envoie au BO la date/heure de la config PDA
--  IN           : p_config_pda de type API_CORE.PDA_CONFIG_TYPE
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.26 | Hocine HAMMOU
--          |
-- ---------------------------------------------------------------------------

PROCEDURE SetConfig(p_config_pda IN api_core.PDA_CONFIG_TYPE, p_FILE_ID OUT INTEGER )
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetConfig';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams        VARCHAR2(4000);
   l_relevant_properties   VARCHAR2(4000);

BEGIN

   -- -----------------------------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE : PDA_ID,   ....
   -- -----------------------------------------------------------------------------------------------------
   l_requiredparams := p_config_pda.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   IF p_config_pda.TAB_PDA_CONFIG IS NOT NULL THEN
      -- on vérifie le tableau contient des périodes, sinon on raise une error ???
	  IF p_config_pda.TAB_PDA_CONFIG.COUNT = 0 THEN
         RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
      END IF;

      -- -- ----------------------------------
      -- -- SI OK on insère ou bien non ???
      -- -- ----------------------------------

      p_FILE_ID := PROCESS_CONFIG( p_config_pda => p_config_pda );

   END IF;


EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetConfig;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement d'intégration en asynchron des infos CONFIG
--               comme le ferait le process_all (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_config( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_config';
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
END process_xmlfile_config;



END PCK_CONFIG_FOR_PDA;

/
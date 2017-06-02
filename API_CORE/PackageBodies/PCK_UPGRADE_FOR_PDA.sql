CREATE OR REPLACE PACKAGE BODY api_core.PCK_UPGRADE_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_UPGRADE_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers UPGRADE
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
--  V01.002 | 2016.08.23 | Hocine HAMMOU
--          | TASK#59407 Correction de la génération du filename xml : c_FILE_SENDER='PDA' remplacé par c_FILE_SENDER='SERV'
--          |
--  V01.003 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
--          |
-- ***************************************************************************
IS

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_UPGRADE_PDA.UPGRADE_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'SERV';                  -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'UPGRADE';              -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                   -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_EVT_LINE_NUMBER              CONSTANT PLS_INTEGER  := 1;                      -- IMPORT_PDA......LINE_NBR initialisé a 1 car un seul evenement par fichier
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';     --
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de UPGRADE
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_upgrade_pda IN PDA_UPGRADE_TYPE     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_ID     IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
BEGIN

  l_file_name :=                           c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_upgrade_pda.FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || p_upgrade_pda.FILE_PDA_BUILD
               || c_FILE_NAME_SEPARATOR || p_upgrade_pda.FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_upgrade_pda.FILE_DTM,c_FILE_DTM_MASK)
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
--               meant to receive information for UPGRADE
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_UPGRADE_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  PROCESS_UPGRADE( p_upgrade_pda IN api_core.PDA_UPGRADE_TYPE ) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_UPGRADE';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_upgrade_file_name   IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id          IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_file_state          NUMBER(1) := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   l_site_timezone       MASTER.SITE.TIMEZONE%TYPE;  -- 2017.01.24 projet [10237]

BEGIN
   -------------------------------------------------------------------------------
   --    RECUPERATION DE LA TIMEZONE DU PDA -- [10237] -- 2017.01.24
   -------------------------------------------------------------------------------
   l_site_timezone := MASTER_PROC.PCK_SITE.GetPDATimezone(p_pda_id => p_upgrade_pda.FILE_PDA_ID );

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_upgrade_file_name := filename( p_upgrade_pda => p_upgrade_pda, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_upgrade_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => p_upgrade_pda.FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_upgrade_pda.FILE_PDA_ID
                                    , p_file_dtm        => p_upgrade_pda.FILE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_UPGRADE_IMPORTED
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_UPGRADE_IMPORTED.InsertUpgradeImported( p_file_id     => l_filexml_id
                                                        , p_line_nbr    => c_EVT_LINE_NUMBER
                                                        , p_build_id    => p_upgrade_pda.BUILD_ID
                                                        , p_upgrade_dtm => (FROM_TZ(CAST(p_upgrade_pda.UPGRADE_DTM AS TIMESTAMP) , l_site_timezone )) AT TIME ZONE 'UTC' -- 2017.01.24 [10237] DATE INTERGREE EN UTC CAR LA COLONNE CIBLE N'EST PAS TIMESTAMP WITH TIME ZONE
                                                        );

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END PROCESS_UPGRADE;



-- ---------------------------------------------------------------------------
--  UNIT         : SetUpgrade
--  DESCRIPTION  : Envoie au BO les infos UPGRADE de PDA
--  IN           : p_upgrade_pda de type API_CORE.PDA_UPGRADE_TYPE
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          |
-- ---------------------------------------------------------------------------

PROCEDURE SetUpgrade(p_upgrade_pda IN api_core.PDA_UPGRADE_TYPE, p_FILE_ID OUT INTEGER )
IS
   l_unit                 MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetUpgrade';
   l_start_date           MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams       VARCHAR2(4000);
   l_relevant_properties  VARCHAR2(4000);

BEGIN

   -- -----------------------------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE : PDA_ID,   ....
   -- -----------------------------------------------------------------------------------------------------
   l_requiredparams := p_upgrade_pda.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ----------------------------------
   -- Traitement d'insertion
   -- ----------------------------------
   p_FILE_ID := PROCESS_UPGRADE( p_upgrade_pda => p_upgrade_pda );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PDA UPGRADE (PDA_ID:'|| p_upgrade_pda.FILE_PDA_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetUpgrade;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement d'intégration en asynchron des events Upgrade
--               comme le ferait le process_all (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_upgrade( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_upgrade';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
-- l_trace VARCHAR2(32000);
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
END process_xmlfile_upgrade;



END PCK_UPGRADE_FOR_PDA;

/
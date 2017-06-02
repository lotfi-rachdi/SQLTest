CREATE OR REPLACE PACKAGE BODY api_core.PCK_INVENTORY
-- ***************************************************************************
--  PACKAGE     : PCK_INVENTORY
--  DESCRIPTION : Package gérant les fichiers INVENTORY
--                envoyés par la WEBAPP/Mobile via les WEB API
--                --> Invenataires sacoches
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.11.28 | Hocine HAMMOU
--          | [10472] Mise en place de l'inventaire matériel ( sacoches...)
--
--  V01.000 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
-- ***************************************************************************
IS

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_INVENTORY.INVENTORY_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'SITE';                         -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_INVENTORY';                  -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                          -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                           -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';             --
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de inventory
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_FILE_PDA_ID   IN VARCHAR2     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_DTM_UTC  IN DATE
                 , p_FILE_ID       IN PLS_INTEGER
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


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for inventory
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.inventory_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  PROCESS_inventory( p_inventory IN api_core.INVENTORY_TYPE ) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_inventory';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_inventory_file_name IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id          IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_site_id             MASTER.SITE.SITE_ID%TYPE;
   l_file_state          NUMBER(1);
   l_SiteTestTypeId      SITE.TEST_TYPE_ID%TYPE;
   l_site_timezone       MASTER.SITE.TIMEZONE%TYPE;      -- 2017.01.24 projet [10237]
BEGIN

   -- -----------------------------------------------------------------------------
   -- A PARTIR DU INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_inventory.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_inventory.INTERNATIONAL_SITE_ID );
   END IF;

   -- -----------------------------------------------------------------------------
   -- RECUPERATION DE LA TIMEZONE DU PUDO
   -- -----------------------------------------------------------------------------
   l_site_timezone := MASTER_PROC.PCK_SITE.GetSiteTimezone(p_siteid => l_site_id);

   -- -----------------------------------------------------------------------------
   -- CONTROLE SI VRAI PUDO (PAS FORMATION, PAS TRAINING
   -- -----------------------------------------------------------------------------
   l_file_state := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML; -- 2016.08.23
   l_SiteTestTypeId:= PCK_SITE.SiteTestTypeId( p_site_id => l_site_id );
   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN
      l_file_state := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   ELSE
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_site_type_id,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||p_inventory.INTERNATIONAL_SITE_ID||').');
   END IF;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_inventory_file_name := filename( p_FILE_PDA_ID => p_inventory.INTERNATIONAL_SITE_ID, p_FILE_DTM_UTC => l_start_date_UTC, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_inventory_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => c_FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_inventory.INTERNATIONAL_SITE_ID
                                    , p_file_dtm        => l_start_date_UTC
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.INVENTORY_IMPORTED
   -- ------------------------------------------------------------------------
   IF p_inventory.TAB_INVENTORY IS NOT NULL THEN
      IF p_inventory.TAB_INVENTORY.COUNT > 0 THEN
         FOR i IN p_inventory.TAB_INVENTORY.FIRST .. p_inventory.TAB_INVENTORY.LAST
         LOOP
            IMPORT_PDA.PCK_inventory_IMPORTED.InsertInventoryImported( p_file_id       => l_filexml_id
                                                                     , p_line_nbr      => i
                                                                     , p_pda_id        => p_inventory.INTERNATIONAL_SITE_ID
                                                                     , p_libelle       => p_inventory.TAB_INVENTORY(i).LIBELLE
                                                                     , p_quantity      => p_inventory.TAB_INVENTORY(i).QUANTITY
                                                                     , p_inventory_dtm => (FROM_TZ(CAST(p_inventory.TAB_INVENTORY(i).INVENTORY_DTM AS TIMESTAMP) , l_site_timezone )) AT TIME ZONE 'UTC' -- 2017.01.24 [10237] DATE INTERGREE EN UTC CAR LA COLONNE CIBLE N'EST PAS TIMESTAMP WITH TIME ZONE
                                                                     , p_origin        => p_inventory.TAB_INVENTORY(i).ORIGIN
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
END PROCESS_inventory;



-- ---------------------------------------------------------------------------
--  UNIT         : SetInventory
--  DESCRIPTION  : Envoie au BO les informations INVENTORY
--  IN           : p_inventory de type API_CORE.INVENTORY_TYPE
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          |
-- ---------------------------------------------------------------------------

PROCEDURE SetInventory(p_inventory IN api_core.INVENTORY_TYPE, p_FILE_ID OUT INTEGER )
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetInventory';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams        VARCHAR2(4000);
   l_relevant_properties   VARCHAR2(4000);

BEGIN

   -- -----------------------------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE : INTERNATIONAL_SITE_ID,   ....
   -- -----------------------------------------------------------------------------------------------------
   l_requiredparams := p_inventory.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   IF p_inventory.TAB_INVENTORY IS NOT NULL THEN
      -- on vérifie le tableau contient des data ??
      IF p_inventory.TAB_INVENTORY.COUNT = 0 THEN
         RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
      END IF;

      -- -- ----------------------------------
      -- -- SI OK on insère ou bien non ???
      -- -- ----------------------------------

      p_FILE_ID := PROCESS_inventory( p_inventory => p_inventory );

      MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] INVENTORY INSERTED (INTERNATIONAL_SITE_ID:'|| p_inventory.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

   END IF;


EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetInventory;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement d'intégration en asynchron des events inventory
--               comme le ferait le process_all (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_inventory( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_inventory';
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
END process_xmlfile_inventory;



END PCK_INVENTORY;

/
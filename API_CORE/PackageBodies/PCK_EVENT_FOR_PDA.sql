CREATE OR REPLACE PACKAGE BODY api_core.PCK_EVENT_FOR_PDA IS
-- ***************************************************************************
--  PACKAGE BODY: PCK_EVENT_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers T_EVENT et T_EVENT_PROPERTIES
--                envoyés par le PDA via les WEB API
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.18 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
--          |
--  V01.001 | 2016.08.23 | Hocine HAMMOU
--          | TASK#59398 Suppression du contrôle fait sur le TEST_TYPE_ID du SITE
--          |
--  V01.002 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
--          |
--  V01.003 | 2017.04.25 | Hocine HAMMOU
--          | MCO : BUG 85317 sur les association/dissociations PDA/PUDO et PDA_INFO.TIMEZONE non renseigné
--          |       ajout exception pour pour traiter et intégrer dans le BO les evenements pour lesquels la déduction de l'association PDA/PUDO a echoué.
--          |       Ces evenements auront exceptionnellement un FILE_STATE égale à 5 de manière à pouvoir les identifier.
--          |       Exceptionnellement la timezone de la date de l'evenement sera fixé par défaut à 'UTC'.
-- ***************************************************************************

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_TRACING_PDA.TRACING_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'PDA'; --IMPORT_PDA.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API; -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_EVENT';                                        -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                                            -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_STATUS_BUILD                 CONSTANT VARCHAR2(15) := 'NA';                                             -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_EVT_LINE_NUMBER              CONSTANT PLS_INTEGER  := 1;                                                -- IMPORT_PDA.T_EVENT_IMPORTED.LINE_NBR initialisé a 1 car un seul evenement par fichier
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';                               -- IMPORT_PDA.T_EVENT_IMPORTED.LINE_NBR initialisé a 1 car un seul evenement par fichier
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';
c_EVENT_ID                     INTEGER               := 1;                                                -- IMPORT_PDA.T_EVENT_IMPORTED.PDA_EVENT_ID
c_PARCEL_KNOWN                 CONSTANT NUMBER(1)    := 0;                                                -- Flag 1/0 --> IMPORT_PDA.T_EVENT_IMPORTED.PARCEL_KNOWN
c_TIMESTAMP_TIME_ZONE          CONSTANT VARCHAR2(50) := 'Europe/Paris';                                   -- pour faire pareil que IMPORT_PDA.PCK_TRACING_PDA.TRACING_PDA_V1_STEP1


-- record and list to store the properties in key - value format
TYPE evt_prop_type IS RECORD
   ( property_name  IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_NAME%TYPE
   , property_value IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE%TYPE
   );
TYPE evt_prop_tab_type IS TABLE OF evt_prop_type;

FUNCTION filename( p_evt_pda      IN PDA_EVT_TYPE  -- p_FILE_PDA_ID  IN VARCHAR2     --ENTRY_FILE.SITE_ID%TYPE
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
               || c_FILE_NAME_SEPARATOR || p_evt_pda.FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || p_evt_pda.FILE_PDA_BUILD
               || c_FILE_NAME_SEPARATOR || p_evt_pda.FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_evt_pda.FILE_DTM,c_FILE_DTM_MASK)
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : recevies a list and a key-value record
--               initializes the list if it is empty
--               adds the row to the list
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
PROCEDURE addKeyValue(p_list IN OUT NOCOPY evt_prop_tab_type, p_prop IN evt_prop_type)
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'addKeyValue';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   IF p_prop.PROPERTY_NAME IS NOT NULL THEN
      IF p_list IS NULL THEN
	     p_list := new evt_prop_tab_type();
      END IF;
      p_list.extend;
      p_list(p_list.COUNT):= p_prop;
   END if;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END addKeyValue;

-- ---------------------------------------------------------------------------
-- ATTENTION AN OVERLOAD OF THIS FUNCTION MUST EXIST FOR EVERY POSSIBLE PROPERTY TYPE
-- OTHERWISE if we call the overload treating integers with a float, we will loose decimal positions
--
-- DESCRIPTION : Transforms property of NUMBER type into a key-value pair
-- ---------------------------------------------------------------------------
-- PARAMETERS  : p_property_value the value of the NUMBER property
--             :
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_property_value IN NUMBER, p_property_name IN VARCHAR2, p_property_mask IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   IF PCK_API_TOOLS.ITEM_IN_LIST(P_LIST => p_relevant_properties, p_item => p_property_name) then
      IF p_property_value is not null then
         l_prop.PROPERTY_NAME := p_property_name;
         IF p_property_mask is not null then
            l_prop.PROPERTY_VALUE := to_char(p_property_value, p_property_mask);
         ELSE
            l_prop.PROPERTY_VALUE := p_property_value; -- conversion implicite
         END IF;
      END IF;
   END IF;

   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- ATTENTION AN OVERLOAD OF THIS FUNCTION MUST EXIST FOR EVERY POSSIBLE PROPERTY TYPE
-- OTHERWISE if we call the overload treating integers with a float, we will loose decimal positions
--
-- DESCRIPTION : Transforms property of VARCHAR type into a key-value pair
-- ---------------------------------------------------------------------------
-- PARAMETERS  : p_property_value the value of the VARCHAR property
--             :
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_property_value IN VARCHAR, p_property_name IN VARCHAR2, p_property_mask IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   IF PCK_API_TOOLS.ITEM_IN_LIST (P_LIST => p_relevant_properties, p_item => p_property_name) then
      IF p_property_value is not null then
         l_prop.PROPERTY_NAME := p_property_name;
         IF p_property_mask is not null then
            l_prop.PROPERTY_VALUE := to_char(p_property_value, p_property_mask);
         ELSE
            l_prop.PROPERTY_VALUE := p_property_value; -- conversion implicite
         END IF;
      END IF;
   END IF;

   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for one event
--               together with an array of properties in key-value format
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_EVENT_IMPORTED
--                 · IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED (in key-value format)
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  INS_EVT
( p_evt_pda_type    IN VARCHAR
, p_event_id        IN NUMBER
, p_evt_pda         IN api_core.PDA_EVT_TYPE
, p_properties      IN evt_prop_tab_type
) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_evt_file_name    IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id       IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_count_properties INTEGER;
   l_site_id          MASTER.SITE.SITE_ID%TYPE;
   l_file_state        NUMBER(1) := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   l_site_timezone MASTER.SITE.TIMEZONE%TYPE;
   l_country_code  MASTER.SITE.COUNTRY_CODE%TYPE;
   l_language_code MASTER.SITE.LANGUAGE_CODE%TYPE;
   l_timezone          MASTER.SITE.TIMEZONE%TYPE;
   l_event_dtm_with_TZ TIMESTAMP WITH TIME ZONE;
BEGIN

   -- 2017.04.25 BUG 85317 CREATION BLOC BEGIN END avec EXCEPTION
   BEGIN
   -- -----------------------------------------------------------------------------
   --    RECUPERATION DE LA TIMEZONE DU PDA -- [10237] -- 2017.01.13
   -- -----------------------------------------------------------------------------
   l_site_timezone := MASTER_PROC.PCK_SITE.GetPDATimezone(p_pda_id => p_evt_pda.FILE_PDA_ID);
   l_event_dtm_with_TZ := FROM_TZ(CAST(p_evt_pda.LOCAL_DTM AS TIMESTAMP) , l_site_timezone);

   -- mise en commentaire 2017.04.25
   -- --------------------------------------------------------------------------------------
   -- A PARTIR DU PDA_ID ET DE LA DATE D'EVENEMENT, RECUPERATION DU SITE_ID RATTACHE AU PDA
   -- --------------------------------------------------------------------------------------
   --  l_site_id := MASTER_PROC.PCK_SITE.GetSiteid(p_pdaid => p_evt_pda.FILE_PDA_ID
   --                                           ,p_date  => sys_extract_utc(l_event_dtm_with_TZ)
   --                          );
   EXCEPTION
      WHEN OTHERS THEN
        l_site_timezone := 'UTC';
        l_file_state := 5;
        MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date);
   END;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_evt_file_name := filename( p_evt_pda => p_evt_pda
                              , p_file_id => l_filexml_id
                              );

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => 'l_filexml_id : ' || to_char(l_filexml_id)   );
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_evt_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => p_evt_pda.FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_evt_pda.FILE_PDA_ID
                                    , p_file_dtm        => p_evt_pda.FILE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_STATUS_BUILD
                                    );

   IF p_properties IS NOT NULL THEN
     l_count_properties :=  p_properties.COUNT;
   END IF;

   IMPORT_PDA.PCK_EVENT_IMPORTED.InsertEventImported( p_file_id         => l_filexml_id
                                                    , p_line_nbr        => c_EVT_LINE_NUMBER
                                                    , p_bo_parcel_id    => p_evt_pda.BO_PARCEL_ID
                                                    , p_parcel_known    => p_evt_pda.PARCEL_KNOWN
                                                    , p_firm_id         => p_evt_pda.FIRM_ID
                                                    , p_firm_parcel_id  => p_evt_pda.FIRM_PARCEL_ID
                                                    , p_pda_event_id    => p_evt_pda.PDA_EVENT_ID
                                                    , p_event_type_id   => p_evt_pda_type
                                                    , p_dtm             => FROM_TZ(CAST(p_evt_pda.LOCAL_DTM AS TIMESTAMP ) , l_site_timezone ) -- 2017.01.03 projet [10237]
                                                    , p_properties_qty  => NVL(l_count_properties,0)
                                                    );

   FOR i IN 1 .. NVL(l_count_properties,0)
   LOOP
      -- --------------------------------------------------------------------------------------------
      -- insert properties common to every event type in IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED     -
      -- --------------------------------------------------------------------------------------------
      -- des valeurs qui seraient dans le type et pourtant mappes comme property??
      -- ----------------------------------------------------------------------------------------------------
      -- insert specific properties received in key-value list into IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED  -
      -- ----------------------------------------------------------------------------------------------------
      IMPORT_PDA.PCK_EVENT_IMPORTED.InsertEventPropertiesImported( p_file_id        => l_filexml_id
                                                                 , p_line_nbr       => i
                                                                 , p_pda_event_id   => p_evt_pda.PDA_EVENT_ID
                                                                 , p_property_name  => p_properties(i).property_name
                                                                 , p_property_value => p_properties(i).property_value
                                                                 );


   END LOOP;

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type PICKUP
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt_pda         --> information common to every event as well as specific PICKUP event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE INS_EVT_FOR_PDA( p_evt_pda IN PDA_EVT_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'INS_EVT_FOR_PDA';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   -- l_trace VARCHAR2(32000);
   l_PDA_EVT_TYPE  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE ;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties VARCHAR2(4000);
BEGIN

   -- -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt_pda.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   l_PDA_EVT_TYPE := p_evt_pda.EVENT_TYPE_ID;

   -- ------------------------------------------------------------------------
   -- controle si le nbre de property est cohérent avec le contenu du tableau EVENT_PROPERTIES (clé/valeurs)
   -- ------------------------------------------------------------------------
   --IF p_evt_pda.PROPERTIES_QTY > 0 THEN -- 15.06.2016 BUG50641
   IF p_evt_pda.EVENT_PROPERTIES IS NOT NULL THEN  -- 15.06.2016 BUG50641
      IF p_evt_pda.EVENT_PROPERTIES.COUNT > 0 THEN
         -- ----------------------------------
         -- SI OK on inscre ou bien non ???
	     -- si aucune property doit-on quand même insérer
         -- ----------------------------------

	     SELECT l.PROPERTY_NAME, l.PROPERTY_VALUE
	     BULK COLLECT INTO l_prop_list
	     FROM TABLE(cast(p_evt_pda.EVENT_PROPERTIES AS api_core.tab_property_type )) l ;

      END IF;
   END IF;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_pda_type   => l_PDA_EVT_TYPE
      , p_event_id       => p_evt_pda.PDA_EVENT_ID
      , p_evt_pda        => p_evt_pda
      , p_properties     => l_prop_list --p_evt_pda.EVENT_PROPERTIES --l_prop_list
      );


   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_PDA_EVT_TYPE ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt_pda.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END INS_EVT_FOR_PDA;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de l'event
--               de faeon proche a comme le ferait le process_all
--               en asynchron (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_event( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_event';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF p_FILE_ID IS NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || p_FILE_ID);
   END IF;

   IMPORT_PDA.PROCESS_XMLFILE_STEP2 ( p_xmlfile_id  => p_FILE_ID , p_action => c_JOB_ACTION );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE]  JOB LAUNCHED (FILE_ID:'||  p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END process_xmlfile_event;


END PCK_EVENT_FOR_PDA;

/
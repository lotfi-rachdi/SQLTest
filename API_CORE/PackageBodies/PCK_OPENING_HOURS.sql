CREATE OR REPLACE PACKAGE BODY api_core.PCK_OPENING_HOURS
-- ***************************************************************************
--  PACKAGE     : PCK_OPENING_HOURS
--  DESCRIPTION : Package to deal with Opening Hours coming from web API
--                inspired from and reusing how XML files of types
--                T_OPENING_HOURS coming from PDAs are uploaded
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.24 | Hocine HAMMOU
--          | Init
--          |
--  V01.001 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
-- ***************************************************************************
IS
c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_OPENING_HOURS_PDA.OPENING_HOURS_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := IMPORT_PDA.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API; -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_OPENING_HOURS';                                -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                                            -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_FILE_STATUS_BUILD            CONSTANT VARCHAR2(15) := 'NA';                                             -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';

-- record and list to store the properties in key - value format
TYPE row_openinghours_type IS RECORD
   ( LINE_NBR         NUMBER      -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.LINE_NBR%TYPE
   , DAY_ID           NUMBER(1)   -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.DAY_ID%TYPE
   , OPEN_TM          VARCHAR2(5) -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.OPEN_TM%TYPE
   , CLOSE_TM         VARCHAR2(5) -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.CLOSE_TM%TYPE
   --, LAST_UPDATE_DTM  TIMESTAMP(6) WITH TIME ZONE -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.LAST_UPDATE_DTM%TYPE
   );
TYPE tab_row_openinghours IS TABLE OF row_openinghours_type;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de OpeningHours
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



-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  :
--  PARAMETER OUT :
-- ---------------------------------------------------------------------------
-- PROCEDURE set_row_openinghours
PROCEDURE set_row_openinghours( p_tab_row_openinghours IN OUT NOCOPY tab_row_openinghours, p_Day_id IN INTEGER , p_Day_openinghours IN api_core.TAB_OPENING_HOURS_TIME_TYPE )
IS l_unit        MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'set_row_openinghours';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_Line_Nbr integer;
BEGIN
      l_Line_Nbr := p_tab_row_openinghours.count;
      l_Line_Nbr := l_Line_Nbr + 1;
   IF p_Day_openinghours IS NOT NULL Then

      FOR i in p_Day_openinghours.FIRST .. p_Day_openinghours.LAST
      LOOP
         p_tab_row_openinghours.extend;
         p_tab_row_openinghours(l_Line_Nbr).DAY_ID := p_Day_id;
         p_tab_row_openinghours(l_Line_Nbr).LINE_NBR := l_Line_Nbr;
         p_tab_row_openinghours(l_Line_Nbr).OPEN_TM  := p_Day_openinghours(i).OPEN_TIME;
         p_tab_row_openinghours(l_Line_Nbr).CLOSE_TM := p_Day_openinghours(i).CLOSE_TIME;
         l_Line_Nbr := l_Line_Nbr+1;
      END LOOP;
   ELSE
         p_tab_row_openinghours.extend;
         p_tab_row_openinghours(l_Line_Nbr).DAY_ID := p_Day_id;
         p_tab_row_openinghours(l_Line_Nbr).LINE_NBR := l_Line_Nbr;
         p_tab_row_openinghours(l_Line_Nbr).OPEN_TM  := PCK_API_CONSTANTS.c_Day_CLOSED;
         p_tab_row_openinghours(l_Line_Nbr).CLOSE_TM := PCK_API_CONSTANTS.c_Day_CLOSED;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END set_row_openinghours;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for opening hours
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_OPENING_HOURS_IMPORTED
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION TRT_OPENING_HOURS( p_opening_hours IN api_core.OPENING_HOURS_TYPE ) RETURN INTEGER -- return p_FILE_ID
IS
   l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'TRT_OPENING_HOURS';
   l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
-- l_trace                 VARCHAR2(32000);
   l_start_date_UTC        DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_openinghour_file_name IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id            IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_site_id               MASTER.SITE.SITE_ID%TYPE;
   l_file_state            NUMBER(1);
   l_SiteTestTypeId        SITE.TEST_TYPE_ID%TYPE;
   l_tab_row_openinghours  tab_row_openinghours;   -- 2015.12.10
   l_timezone              MASTER.SITE.TIMEZONE%TYPE;      -- 2017.01.20 projet [10237]
BEGIN

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_opening_hours.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_opening_hours.INTERNATIONAL_SITE_ID);
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
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_site_type_id,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'|| p_opening_hours.INTERNATIONAL_SITE_ID ||').');
   END IF;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_openinghour_file_name := filename( p_FILE_PDA_ID => p_opening_hours.INTERNATIONAL_SITE_ID, p_FILE_DTM_UTC => l_start_date_UTC, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_openinghour_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => c_FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_opening_hours.INTERNATIONAL_SITE_ID
                                    , p_file_dtm        => p_opening_hours.LAST_UPDATE_DTM
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_FILE_STATUS_BUILD
                                    );


   -- ------------------------------------------------------------------------
   -- Validation et mise en forme du message pour traitement et insertion dans IMPORT_PDA.T_OPENING_HOURS_IMPORTED
   -- initialisation du tableau
   -- ------------------------------------------------------------------------
   l_tab_row_openinghours := new tab_row_openinghours();
   --Lundi
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_MONDAY_ID   , p_Day_openinghours => p_opening_hours.DAY_MONDAY );
   --MARDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_TUESDAY_ID  , p_Day_openinghours => p_opening_hours.DAY_TUESDAY );
   --MERCREDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_WEDNESDAY_ID, p_Day_openinghours => p_opening_hours.DAY_WEDNESDAY );
   --JEUDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_THURSDAY_ID , p_Day_openinghours => p_opening_hours.DAY_THURSDAY );
   --VENDREDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_FRIDAY_ID   , p_Day_openinghours => p_opening_hours.DAY_FRIDAY );
   --SAMEDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_SATURDAY_ID , p_Day_openinghours => p_opening_hours.DAY_SATURDAY );
   --DIMANCHE
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_SUNDAY_ID   , p_Day_openinghours => p_opening_hours.DAY_SUNDAY );


   -- ------------------------------------------------------------------------
   -- INSERT INTO    IMPORT_PDA.T_OPENING_HOURS_IMPORTED
   -- ------------------------------------------------------------------------
   IF l_tab_row_openinghours IS NOT NULL THEN
      FOR i In l_tab_row_openinghours.FIRST .. l_tab_row_openinghours.LAST
      LOOP
         IMPORT_PDA.PCK_OPENING_HOURS_IMPORTED.InsertOpeningHoursImported( p_file_id          => l_filexml_id
                                                                         , p_line_nbr         => l_tab_row_openinghours(i).LINE_NBR
                                                                         , p_day_id           => l_tab_row_openinghours(i).DAY_ID
                                                                         , p_open_tm          => l_tab_row_openinghours(i).OPEN_TM
                                                                         , p_close_tm         => l_tab_row_openinghours(i).CLOSE_TM
                                                                         , p_last_update_dtm  => ( FROM_TZ(CAST(p_opening_hours.LAST_UPDATE_DTM AS TIMESTAMP ) , PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ) ) AT TIME ZONE l_timezone -- 2017.01.20 projet [10237] integration date dans la time zone du pudo
                                                                         );
      END LOOP;
   END IF;

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END TRT_OPENING_HOURS;



-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_opening_hours --> information about opening hours
--  PARAMETER OUT : p_FILE_ID       --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE SetSiteOpeningHours( p_opening_hours IN api_core.OPENING_HOURS_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetSiteOpeningHours';
   l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams        VARCHAR2(4000);
   l_relevant_properties   VARCHAR2(4000);
   l_error_openclose_time  VARCHAR2(1000) := NULL;

BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_opening_hours.CheckMsgSetOpeningHours(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE QUE LES HORAIRES SONT VALIDES POUR CHACUNE DES JOURNEES ( HEURE D'OUVERTURE < HEURE D'FERMETURE )
   -- CHECK LUNDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_MONDAY    , PCK_API_CONSTANTS.c_Day_MONDAY   , l_error_openclose_time);
   -- CHECK MARDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_TUESDAY   , PCK_API_CONSTANTS.c_Day_TUESDAY  , l_error_openclose_time);
   -- CHECK MERCREDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_WEDNESDAY , PCK_API_CONSTANTS.c_Day_WEDNESDAY , l_error_openclose_time);
   -- CHECK JEUDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_THURSDAY  , PCK_API_CONSTANTS.c_Day_THURSDAY  , l_error_openclose_time);
   -- CHECK VENDREDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_FRIDAY    , PCK_API_CONSTANTS.c_Day_FRIDAY    , l_error_openclose_time);
   -- CHECK SAMEDI
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_SATURDAY  , PCK_API_CONSTANTS.c_Day_SATURDAY  , l_error_openclose_time);
   -- CHECK DIMANCHE
   l_error_openclose_time := p_opening_hours.CheckOpenCloseTime(p_opening_hours.DAY_SUNDAY    , PCK_API_CONSTANTS.c_Day_SUNDAY    , l_error_openclose_time);

   IF TRIM(l_error_openclose_time) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE]  HORAIRES INVALIDES : ' || l_error_openclose_time);
   END IF;

   -- ------------------------------------------------------------------------
   -- call TRT_OPENING_HOURS FUNCTION to continue the OpeningHours treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= TRT_OPENING_HOURS( p_opening_hours => p_opening_hours); -- 2015.12.10

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] OPENING HOURS INSERTED (INTERNATIONAL_SITE_ID:'|| p_opening_hours.INTERNATIONAL_SITE_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetSiteOpeningHours;





-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  :
--  PARAMETER OUT :
-- ---------------------------------------------------------------------------
PROCEDURE get_row_openinghours( p_DAY_OPENING_HOURS IN OUT NOCOPY TAB_OPENING_HOURS_TIME_TYPE
                               ,p_MORNING_OPEN_TM IN VARCHAR2, p_MORNING_CLOSE_TM IN VARCHAR2, p_EVENING_OPEN_TM IN VARCHAR2, p_EVENING_CLOSE_TM IN VARCHAR2
                              )

IS l_unit        MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'get_row_openinghours';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_tab_opening_hours_time_type api_core.TAB_OPENING_HOURS_TIME_TYPE;
   l_opening_hours_time_type api_core.OPENING_HOURS_TIME_TYPE;

BEGIN

   IF p_MORNING_OPEN_TM = '00:00' AND p_MORNING_CLOSE_TM = '00:00' AND p_EVENING_OPEN_TM = '00:00' AND p_EVENING_CLOSE_TM = '00:00' THEN
      p_DAY_OPENING_HOURS := null; -- journée fermée
   ELSIF ( p_MORNING_CLOSE_TM = '12:00' AND p_EVENING_OPEN_TM = '12:00' ) THEN
   -- cas d'une journée d'ouverture non stop
      -- initialisation des objets
      l_tab_opening_hours_time_type := api_core.TAB_OPENING_HOURS_TIME_TYPE();
      l_opening_hours_time_type := api_core.OPENING_HOURS_TIME_TYPE();
      -- affectation des objets
      l_tab_opening_hours_time_type.EXTEND;
      l_opening_hours_time_type.OPEN_TIME := p_MORNING_OPEN_TM;
      l_opening_hours_time_type.CLOSE_TIME := p_EVENING_CLOSE_TM;
      l_tab_opening_hours_time_type(1) := l_opening_hours_time_type;
      p_DAY_OPENING_HOURS := l_tab_opening_hours_time_type;

   ELSIF ( p_MORNING_OPEN_TM = '00:00' AND p_MORNING_CLOSE_TM = '00:00' ) THEN
   -- cas d'une journée d'ouverture non stop
      -- initialisation des objets
      l_tab_opening_hours_time_type := api_core.TAB_OPENING_HOURS_TIME_TYPE();
      l_opening_hours_time_type := api_core.OPENING_HOURS_TIME_TYPE();
      -- affectation des objets
      l_tab_opening_hours_time_type.EXTEND;
      l_opening_hours_time_type.OPEN_TIME := p_EVENING_OPEN_TM;
      l_opening_hours_time_type.CLOSE_TIME := p_EVENING_CLOSE_TM;
      l_tab_opening_hours_time_type(1) := l_opening_hours_time_type;
      p_DAY_OPENING_HOURS := l_tab_opening_hours_time_type;

   ELSIF ( p_EVENING_OPEN_TM = '00:00' AND p_EVENING_CLOSE_TM = '00:00' ) THEN
   -- cas d'une journée d'ouverture non stop
      -- initialisation des objets
      l_tab_opening_hours_time_type := api_core.TAB_OPENING_HOURS_TIME_TYPE();
      l_opening_hours_time_type := api_core.OPENING_HOURS_TIME_TYPE();
      -- affectation des objets
      l_tab_opening_hours_time_type.EXTEND;
      l_opening_hours_time_type.OPEN_TIME := p_MORNING_OPEN_TM;
      l_opening_hours_time_type.CLOSE_TIME := p_MORNING_CLOSE_TM;
      l_tab_opening_hours_time_type(1) := l_opening_hours_time_type;
      p_DAY_OPENING_HOURS := l_tab_opening_hours_time_type;

   ELSIF p_MORNING_CLOSE_TM <> p_EVENING_OPEN_TM THEN -- cas d'une journée d'ouverture avec deux périodes d'ouverture dans la journée
      -- initialisation des objets
      l_tab_opening_hours_time_type := api_core.TAB_OPENING_HOURS_TIME_TYPE();
      l_opening_hours_time_type := api_core.OPENING_HOURS_TIME_TYPE();
      -- affectation des objets
      l_tab_opening_hours_time_type.EXTEND;
      l_opening_hours_time_type.OPEN_TIME := p_MORNING_OPEN_TM;
      l_opening_hours_time_type.CLOSE_TIME := p_MORNING_CLOSE_TM;
      l_tab_opening_hours_time_type(1) := l_opening_hours_time_type;
      l_tab_opening_hours_time_type.EXTEND;
      l_opening_hours_time_type.OPEN_TIME := p_EVENING_OPEN_TM;
      l_opening_hours_time_type.CLOSE_TIME := p_EVENING_CLOSE_TM;
      l_tab_opening_hours_time_type(2) := l_opening_hours_time_type;
      p_DAY_OPENING_HOURS := l_tab_opening_hours_time_type;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END get_row_openinghours;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : GetSiteOpeningHours
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_opening_hours --> information about opening hours
--  PARAMETER OUT : p_FILE_ID       --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteOpeningHours( p_opening_hours IN OUT NOCOPY api_core.OPENING_HOURS_TYPE)
IS l_unit                      MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteOpeningHours';
   l_start_date                MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams            VARCHAR2(4000);
   l_relevant_properties       VARCHAR2(4000);
   l_site_id                   MASTER.SITE.SITE_ID%TYPE;
   l_site_opening_hours        MASTER.OPENING_HOURS%ROWTYPE;
--   l_TAB_OPENINGHOURS_FILE_ID  API_CORE.TAB_ELEMENT_NUMBER_TYPE;
   l_TAB_OPENINGHOURS_FILE_ID  IMPORT_PDA.PCK_OPENING_HOURS_IMPORTED.TAB_ELEMENT_NUMBER_TYPE;

BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_opening_hours.CheckMsgGetOpeningHours(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_opening_hours.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_opening_hours.INTERNATIONAL_SITE_ID);
   END IF;

   -- -----------------------------------------------------------------------------
   -- RETRIEVE DES DONNEES OPENING_HOURS DU SITE
   -- -----------------------------------------------------------------------------
   SELECT o.*
   INTO l_site_opening_hours
   FROM  MASTER.OPENING_HOURS o
   WHERE o.site_id = l_site_id;


   --LUNDI
   get_row_openinghours ( p_opening_hours.DAY_MONDAY, l_site_opening_hours.MON_MORNING_OPEN_TM, l_site_opening_hours.MON_MORNING_CLOSE_TM, l_site_opening_hours.MON_EVENING_OPEN_TM, l_site_opening_hours.MON_EVENING_CLOSE_TM);
   --MARDI
   get_row_openinghours ( p_opening_hours.DAY_TUESDAY, l_site_opening_hours.TUE_MORNING_OPEN_TM, l_site_opening_hours.TUE_MORNING_CLOSE_TM, l_site_opening_hours.TUE_EVENING_OPEN_TM, l_site_opening_hours.TUE_EVENING_CLOSE_TM);
   --MERCREDI
   get_row_openinghours ( p_opening_hours.DAY_WEDNESDAY, l_site_opening_hours.WED_MORNING_OPEN_TM, l_site_opening_hours.WED_MORNING_CLOSE_TM, l_site_opening_hours.WED_EVENING_OPEN_TM, l_site_opening_hours.WED_EVENING_CLOSE_TM);
   --JEUDI
   get_row_openinghours ( p_opening_hours.DAY_THURSDAY, l_site_opening_hours.THU_MORNING_OPEN_TM, l_site_opening_hours.THU_MORNING_CLOSE_TM, l_site_opening_hours.THU_EVENING_OPEN_TM, l_site_opening_hours.THU_EVENING_CLOSE_TM);
   --VENDREDI
   get_row_openinghours ( p_opening_hours.DAY_FRIDAY, l_site_opening_hours.FRI_MORNING_OPEN_TM, l_site_opening_hours.FRI_MORNING_CLOSE_TM, l_site_opening_hours.FRI_EVENING_OPEN_TM, l_site_opening_hours.FRI_EVENING_CLOSE_TM);
   --SAMEDI
   get_row_openinghours ( p_opening_hours.DAY_SATURDAY, l_site_opening_hours.SAT_MORNING_OPEN_TM, l_site_opening_hours.SAT_MORNING_CLOSE_TM, l_site_opening_hours.SAT_EVENING_OPEN_TM, l_site_opening_hours.SAT_EVENING_CLOSE_TM);
   --DIMANCHE
   get_row_openinghours ( p_opening_hours.DAY_SUNDAY, l_site_opening_hours.SUN_MORNING_OPEN_TM, l_site_opening_hours.SUN_MORNING_CLOSE_TM, l_site_opening_hours.SUN_EVENING_OPEN_TM, l_site_opening_hours.SUN_EVENING_CLOSE_TM);
   --LAST_UPDATE_DTM  --12.02.2016 BUG MODE DECONNECTE
   --p_opening_hours.LAST_UPDATE_DTM := NVL(l_site_opening_hours.LAST_UPDATE_DTM,l_site_opening_hours.CREATION_DTM);
   p_opening_hours.LAST_UPDATE_DTM := l_site_opening_hours.LAST_UPDATE_DTM AT TIME ZONE PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC;

   -- p_opening_hours.TAB_OPENINGHOURS_FILE_ID := l_site_opening_hours.SITE_ID;
   IMPORT_PDA.PCK_OPENING_HOURS_IMPORTED.GetUnprocessedOpenHoursFileID( p_INTERNATIONAL_SITE_ID => p_opening_hours.INTERNATIONAL_SITE_ID, p_TAB_OPENINGHOURS_FILE_ID => l_TAB_OPENINGHOURS_FILE_ID );
   IF l_TAB_OPENINGHOURS_FILE_ID.COUNT > 0 THEN
      p_opening_hours.TAB_OPENINGHOURS_FILE_ID := NEW api_core.TAB_ELEMENT_NUMBER_TYPE();
      p_opening_hours.TAB_OPENINGHOURS_FILE_ID.EXTEND(l_TAB_OPENINGHOURS_FILE_ID.COUNT);
      FOR j IN l_TAB_OPENINGHOURS_FILE_ID.FIRST .. l_TAB_OPENINGHOURS_FILE_ID.LAST
      LOOP
         p_opening_hours.TAB_OPENINGHOURS_FILE_ID(j) := l_TAB_OPENINGHOURS_FILE_ID(j);
      END LOOP;
   END IF;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] OPENING HOURS RETRIEVED (INTERNATIONAL_SITE_ID:'|| p_opening_hours.INTERNATIONAL_SITE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- CAS OU LE SITE N'A PAS ENCORE D'OPENING HOURS SAISIS, DONC ON RETOURNE COMME SI LE PUDO EST FERME TOUS LES JOURS
      MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] OPENING HOURS NOT EXISTING (INTERNATIONAL_SITE_ID:'|| p_opening_hours.INTERNATIONAL_SITE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteOpeningHours;


-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteOpeningHours
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.12.02 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION  GetSiteOpeningHours(p_international_site_id IN VARCHAR2) RETURN api_core.OPENING_HOURS_TYPE
IS
  l_unit               MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteOpeningHours';
  l_start_date         MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_OPENING_HOURS_TYPE api_core.OPENING_HOURS_TYPE;
BEGIN
  l_OPENING_HOURS_TYPE :=  api_core.OPENING_HOURS_TYPE();
  l_OPENING_HOURS_TYPE.INTERNATIONAL_SITE_ID := p_international_site_id;
  -- GetSiteOpeningHours( p_opening_hours IN OUT API_CORE.OPENING_HOURS_TYPE)
  GetSiteOpeningHours(p_opening_hours => l_OPENING_HOURS_TYPE);
  RETURN l_OPENING_HOURS_TYPE;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteOpeningHours;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de openinghours
--               de façon proche à comme le ferait le process_all
--               en asynchron (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_openinghours( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_openinghours';
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
END process_xmlfile_openinghours;


END PCK_OPENING_HOURS;

/
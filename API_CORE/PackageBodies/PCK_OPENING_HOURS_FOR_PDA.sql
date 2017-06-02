CREATE OR REPLACE PACKAGE BODY api_core.PCK_OPENING_HOURS_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_OPENING_HOURS_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers OPENING HOURS
--                envoyés par le PDA via les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          | Init Projet [10326] Migration PDA vers WebAPI
--          |
--  V01.001 | 2016.08.23 | Hocine HAMMOU
--          | TASK#59398 Suppression du contrôle fait sur le TEST_TYPE_ID du SITE
--          |
--  V01.002 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
-- ***************************************************************************
IS
c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_OPENING_HOURS_PDA.OPENING_HOURS_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := 'PDA'; --IMPORT_PDA.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API; -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_OPENING_HOURS';                                -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
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
   );
TYPE tab_row_openinghours IS TABLE OF row_openinghours_type;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Fonction pour générer le nom attribué au fichier de OpeningHours
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION filename( p_opening_hours_pda IN PDA_OPENING_HOURS_TYPE     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_ID           IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
BEGIN

  l_file_name :=  c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_opening_hours_pda.FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || p_opening_hours_pda.FILE_PDA_BUILD
               || c_FILE_NAME_SEPARATOR || p_opening_hours_pda.FILE_VERSION
               || c_FILE_NAME_SEPARATOR || to_char(p_opening_hours_pda.FILE_DTM,c_FILE_DTM_MASK)
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
FUNCTION PROCESS_OPENING_HOURS( p_opening_hours_pda IN api_core.PDA_OPENING_HOURS_TYPE ) RETURN INTEGER -- return p_FILE_ID
IS
   l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PROCESS_OPENING_HOURS';
   l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_openinghour_file_name IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id            IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_file_state            NUMBER(1) := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   l_tab_row_openinghours  tab_row_openinghours;    -- 2015.12.10
   l_site_timezone         MASTER.SITE.TIMEZONE%TYPE;  -- 2017.01.20 projet [10237]

BEGIN

   -------------------------------------------------------------------------------
   --    RECUPERATION DE LA TIMEZONE DU PDA -- [10237] -- 2017.01.20
   -------------------------------------------------------------------------------
   l_site_timezone := MASTER_PROC.PCK_SITE.GetPDATimezone(p_pda_id => p_opening_hours_pda.FILE_PDA_ID );

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_openinghour_file_name := filename( p_opening_hours_pda => p_opening_hours_pda, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_openinghour_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => p_opening_hours_pda.FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_opening_hours_pda.FILE_PDA_ID
                                    , p_file_dtm        => p_opening_hours_pda.LAST_UPDATE_DTM
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
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_MONDAY_ID   , p_Day_openinghours => p_opening_hours_pda.DAY_MONDAY );
   --MARDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_TUESDAY_ID  , p_Day_openinghours => p_opening_hours_pda.DAY_TUESDAY );
   --MERCREDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_WEDNESDAY_ID, p_Day_openinghours => p_opening_hours_pda.DAY_WEDNESDAY );
   --JEUDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_THURSDAY_ID , p_Day_openinghours => p_opening_hours_pda.DAY_THURSDAY );
   --VENDREDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_FRIDAY_ID   , p_Day_openinghours => p_opening_hours_pda.DAY_FRIDAY );
   --SAMEDI
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_SATURDAY_ID , p_Day_openinghours => p_opening_hours_pda.DAY_SATURDAY );
   --DIMANCHE
   set_row_openinghours( p_tab_row_openinghours => l_tab_row_openinghours , p_Day_id => PCK_API_CONSTANTS.c_Day_SUNDAY_ID   , p_Day_openinghours => p_opening_hours_pda.DAY_SUNDAY );


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
                                                                          , p_last_update_dtm  => FROM_TZ(CAST(p_opening_hours_pda.LAST_UPDATE_DTM AS TIMESTAMP ) , l_site_timezone )  -- 2017.01.20 projet [10237] integration date dans la timezone du pudo
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
END PROCESS_OPENING_HOURS;



-- ---------------------------------------------------------------------------
-- DESCRIPTION :
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_opening_hours_pda --> information about opening hours
--  PARAMETER OUT : p_FILE_ID       --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE SetSiteOpeningHours( p_opening_hours_pda IN api_core.PDA_OPENING_HOURS_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetSiteOpeningHours';
   l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams        VARCHAR2(4000);
   l_relevant_properties   VARCHAR2(4000);
   l_error_openclose_time  VARCHAR2(1000) := NULL;

BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_opening_hours_pda.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE QUE LES HORAIRES SONT VALIDES POUR CHACUNE DES JOURNEES ( HEURE D'OUVERTURE < HEURE D'FERMETURE )
   -- CHECK LUNDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_MONDAY    , PCK_API_CONSTANTS.c_Day_MONDAY   , l_error_openclose_time);
   -- CHECK MARDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_TUESDAY   , PCK_API_CONSTANTS.c_Day_TUESDAY  , l_error_openclose_time);
   -- CHECK MERCREDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_WEDNESDAY , PCK_API_CONSTANTS.c_Day_WEDNESDAY , l_error_openclose_time);
   -- CHECK JEUDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_THURSDAY  , PCK_API_CONSTANTS.c_Day_THURSDAY  , l_error_openclose_time);
   -- CHECK VENDREDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_FRIDAY    , PCK_API_CONSTANTS.c_Day_FRIDAY    , l_error_openclose_time);
   -- CHECK SAMEDI
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_SATURDAY  , PCK_API_CONSTANTS.c_Day_SATURDAY  , l_error_openclose_time);
   -- CHECK DIMANCHE
   l_error_openclose_time := p_opening_hours_pda.CheckOpenCloseTime(p_opening_hours_pda.DAY_SUNDAY    , PCK_API_CONSTANTS.c_Day_SUNDAY    , l_error_openclose_time);

   IF TRIM(l_error_openclose_time) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE]  HORAIRES INVALIDES : ' || l_error_openclose_time);
   END IF;

   -- ------------------------------------------------------------------------
   -- call PROCESS_OPENING_HOURS FUNCTION to continue the OpeningHours treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= PROCESS_OPENING_HOURS( p_opening_hours_pda => p_opening_hours_pda); -- 2015.12.10

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] OPENING HOURS INSERTED (PDA_ID:'|| p_opening_hours_pda.FILE_PDA_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetSiteOpeningHours;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de openinghours
--               de faeon proche a comme le ferait le process_all
--               en asynchron (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_openinghours( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_openinghours';
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
END process_xmlfile_openinghours;


END PCK_OPENING_HOURS_FOR_PDA;

/
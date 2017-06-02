CREATE OR REPLACE TYPE api_core."OPENING_HOURS_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.OPENING_HOURS_TYPE
--  DESCRIPTION : Objet type représentant les horaires d'ouvertures d'un site
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.25 | Hocine HAMMOU
--          | Init
--          |
--  V01.000 | 2016.02.15 | Hocine HAMMOU
--          | [] RM1 LOT2 MODE DECONNECTE
--          | Ajout de l'attribut TAB_OPENINGHOURS_FILE_ID
--          |
-- ***************************************************************************
(
 INTERNATIONAL_SITE_ID     VARCHAR2(35)                    -- MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE
,DAY_MONDAY                TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du LUNDI
,DAY_TUESDAY               TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du MARDI
,DAY_WEDNESDAY             TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du MERCREDI
,DAY_THURSDAY              TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du JEUDI
,DAY_FRIDAY                TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du VENDREDI
,DAY_SATURDAY              TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du SAMEDI
,DAY_SUNDAY                TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou après-midi du DIMANCHE
,LAST_UPDATE_DTM           TIMESTAMP(6) WITH TIME ZONE     -- MASTER.OPENING_HOURS.LAST_UPDATE_DTM	TIMESTAMP(6) WITH TIME ZONE
,TAB_OPENINGHOURS_FILE_ID  TAB_ELEMENT_NUMBER_TYPE         -- TABLEAU D'ELEMENTS NUMBER POUR REPRESENTER => IMPORT_PDA.T_XMLFILES.FILE_ID OU IMPORT_PDA.IMPORT_PDA.T_OPENING_HOURS_IMPORTED

, CONSTRUCTOR FUNCTION OPENING_HOURS_TYPE(SELF IN OUT NOCOPY OPENING_HOURS_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION CheckMsgSetOpeningHours (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION CheckMsgGetOpeningHours (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION CheckOpenCloseTime (p_Day_openinghours IN TAB_OPENING_HOURS_TIME_TYPE, p_DAY IN VARCHAR2 , p_error_message IN OUT VARCHAR2 ) RETURN VARCHAR2

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."OPENING_HOURS_TYPE" IS
-- ***************************************************************************
--  TYPE BODY   : API_CORE.OPENING_HOURS_WEEK_TYPE
--  DESCRIPTION : Méthodes de l'objet type représentant les horaires
--                d'ouvertures d'un site
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.24 | Hocine HAMMOU
--          | Init
-- ***************************************************************************

CONSTRUCTOR FUNCTION OPENING_HOURS_TYPE(SELF IN OUT NOCOPY OPENING_HOURS_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := OPENING_HOURS_TYPE ( INTERNATIONAL_SITE_ID    => NULL
                              , DAY_MONDAY               => NULL
							  , DAY_TUESDAY              => NULL
							  , DAY_WEDNESDAY            => NULL
							  , DAY_THURSDAY             => NULL
							  , DAY_FRIDAY               => NULL
							  , DAY_SATURDAY             => NULL
							  , DAY_SUNDAY               => NULL
							  , LAST_UPDATE_DTM          => NULL
							  , TAB_OPENINGHOURS_FILE_ID => NULL
							  );
   RETURN;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction CheckMsgSetOpeningHours :
 -- fonction qui check la validité du message de création de Opening Hours
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckMsgSetOpeningHours (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckMsgSetOpeningHours';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;

   IF TRIM(LAST_UPDATE_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LAST_UPDATE_DTM');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction CheckMsgGetOpeningHours :
 -- fonction qui check la validité du message lors du get  de Opening Hours
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckMsgGetOpeningHours (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckMsgGetOpeningHours';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;



-- -------------------------------------------------------------------------------------------
 -- Fonction CheckOpenCloseTime :
 -- fonction qui vérifie la validité des heures saisies pour l'ouverture/fermeture d'une journée
 -- retourne TRUE SI OK , FALSE SI KO;
-- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckOpenCloseTime ( p_Day_openinghours IN TAB_OPENING_HOURS_TIME_TYPE , p_DAY IN VARCHAR2 , p_error_message IN OUT VARCHAR2 ) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckOpenCloseTime';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;

   l_time_1 DATE;
   l_time_2 DATE;
   l_time_3 DATE;
   l_time_4 DATE;

   l_result BOOLEAN := TRUE; -- RETURN TRUE SI OK , FALSE SI KO

BEGIN

   IF p_Day_openinghours IS NOT NULL Then
      IF p_Day_openinghours.count = 1 THEN -- 1 période OPEN/CLOSE pour 1 journée  (exemple 08:00/19:00)
         FOR i in p_Day_openinghours.FIRST .. p_Day_openinghours.LAST
	     LOOP
            l_time_1 := TO_DATE(p_Day_openinghours(i).OPEN_TIME,'HH24/SS');
	        l_time_2 := TO_DATE(p_Day_openinghours(i).CLOSE_TIME,'HH24/SS');
         END LOOP;
         IF l_time_1 > l_time_2 THEN
            -- Horaires invalides : heure d'ouverture > heure de fermeture
            IF p_error_message IS NULL THEN
			   p_error_message := p_DAY;
			ELSE
			   p_error_message := p_error_message || ', ' || p_DAY;
			END IF;
         END IF;
      END IF;

      IF p_Day_openinghours.count = 2 THEN -- 2 périodes OPEN/CLOSE pour 1 journée (exemple 08:00/12:00 - 14:00/19:00)
         FOR i in p_Day_openinghours.FIRST .. p_Day_openinghours.LAST
	     LOOP
		    IF i=1 THEN
               l_time_1 := TO_DATE(p_Day_openinghours(i).OPEN_TIME,'HH24/SS');
	           l_time_2 := TO_DATE(p_Day_openinghours(i).CLOSE_TIME,'HH24/SS');
            END IF;

		    IF i=2 THEN
               l_time_3 := TO_DATE(p_Day_openinghours(i).OPEN_TIME,'HH24/SS');
	           l_time_4 := TO_DATE(p_Day_openinghours(i).CLOSE_TIME,'HH24/SS');
            END IF;
         END LOOP;
         IF l_time_1 > l_time_2 OR l_time_3 > l_time_4 OR l_time_2 > l_time_3 THEN
            -- Horaires invalides : heure d'ouverture > heure de fermeture
            IF p_error_message IS NULL THEN
			   p_error_message := p_DAY;
			ELSE
			   p_error_message := p_error_message || ', ' || p_DAY;
			END IF;

         END IF;
	  END IF;
   END IF;

   RETURN p_error_message;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/
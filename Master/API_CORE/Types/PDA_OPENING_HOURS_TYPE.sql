CREATE OR REPLACE TYPE api_core."PDA_OPENING_HOURS_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PDA_OPENING_HOURS_TYPE
--  DESCRIPTION : Objet type représentant les horaires d'ouvertures d'un site
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          | Init Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
(
  FILE_PDA_ID         VARCHAR2(30)                    -- IMPORT_PDA.T_XMLFILES.FILE_PDA_ID
, FILE_PDA_BUILD      VARCHAR2(50)                    --
, FILE_VERSION        VARCHAR2(35)                    -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
, FILE_DTM            DATE                            -- IMPORT_PDA.T_XMLFILES.FILE_DTM
, DAY_MONDAY          TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du LUNDI
, DAY_TUESDAY         TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du MARDI
, DAY_WEDNESDAY       TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du MERCREDI
, DAY_THURSDAY        TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du JEUDI
, DAY_FRIDAY          TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du VENDREDI
, DAY_SATURDAY        TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du SAMEDI
, DAY_SUNDAY          TAB_OPENING_HOURS_TIME_TYPE     -- Horaires douverture/fermeture matin et/ou aprcs-midi du DIMANCHE
, LAST_UPDATE_DTM     TIMESTAMP(6) WITH TIME ZONE     -- MASTER.OPENING_HOURS.LAST_UPDATE_DTM	TIMESTAMP(6) WITH TIME ZONE

, CONSTRUCTOR FUNCTION PDA_OPENING_HOURS_TYPE(SELF IN OUT NOCOPY PDA_OPENING_HOURS_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION CheckOpenCloseTime (p_Day_openinghours IN TAB_OPENING_HOURS_TIME_TYPE, p_DAY IN VARCHAR2 , p_error_message IN OUT VARCHAR2 ) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PDA_OPENING_HOURS_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PDA_OPENING_HOURS_TYPE
--  DESCRIPTION : Description ....
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          | Init Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION PDA_OPENING_HOURS_TYPE(SELF IN OUT NOCOPY PDA_OPENING_HOURS_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PDA_OPENING_HOURS_TYPE
      (  FILE_PDA_ID        => NULL
      ,  FILE_PDA_BUILD     => NULL
      ,  FILE_VERSION       => NULL
      ,  FILE_DTM           => NULL
      ,  DAY_MONDAY         => NULL
      ,  DAY_TUESDAY        => NULL
      ,  DAY_WEDNESDAY      => NULL
      ,  DAY_THURSDAY       => NULL
      ,  DAY_FRIDAY         => NULL
      ,  DAY_SATURDAY       => NULL
      ,  DAY_SUNDAY         => NULL
      ,  LAST_UPDATE_DTM    => NULL
      );

   RETURN;
END;

 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 -- fonction qui check la validité du message de création de Opening Hours
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(FILE_VERSION) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_VERSION');
   END IF;

   IF TRIM(FILE_PDA_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_ID');
   END IF;

   IF TRIM(FILE_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_DTM');
   END IF;

   IF TRIM(FILE_PDA_BUILD) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_BUILD');
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
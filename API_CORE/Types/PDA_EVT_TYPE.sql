CREATE OR REPLACE TYPE api_core."PDA_EVT_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PDA_EVT_TYPE
--  DESCRIPTION : Description des attributs des EVENTS PDA reçu par WEB SERVICES.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.15 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--
-- ***************************************************************************
(
  FILE_PDA_ID         VARCHAR2(30)                        --> actuellement dans le filename, 3ème position
, FILE_PDA_BUILD      VARCHAR2(50)                        --> actuellement dans le filename, ème position
, FILE_VERSION        VARCHAR2(35)                        --> actuellement dans le filename, 5ème position
, FILE_DTM            DATE                                --> actuellement dans le filename, 6ème position
, BO_PARCEL_ID        NUMBER                              --> actuellement balise <BO_PARCEL_ID> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, PARCEL_KNOWN        NUMBER(1)                           --> actuellement balise <PARCEL_KNOWN> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, FIRM_ID             VARCHAR2(50)                        --> actuellement balise <FIRM_ID> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, FIRM_PARCEL_ID      VARCHAR2(50)                        --> actuellement balise <FIRM_PARCEL_ID> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, PDA_EVENT_ID        VARCHAR2(50)                        --> actuellement balise <PDA_EVENT_ID> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, EVENT_TYPE_ID       VARCHAR2(50)                        --> actuellement balise <EVENT_TYPE_ID> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, LOCAL_DTM           TIMESTAMP(6) WITH TIME ZONE                        --> Nota bene : date locale sans TIMEZONE suite aux pb. rencontrés par le .Net de communiquer le bon timezone
, PROPERTIES_QTY      NUMBER                              --> actuellement balise <PROPERTIES_QTY> dans <T_EVENT_ROW> dans les fichiers de type T_EVENT
, EVENT_PROPERTIES    api_core.TAB_PROPERTY_TYPE          --> actuellement balise <PROPERTY_NAME> dans <T_EVENT_PROPERTIES_ROW> dans les fichiers de type T_EVENT_PROPERTIES
                                                          --> actuellement balise <PROPERTY_VALUE> dans <T_EVENT_PROPERTIES_ROW> dans les fichiers de type T_EVENT_PROPERTIES

, CONSTRUCTOR FUNCTION PDA_EVT_TYPE(SELF IN OUT NOCOPY PDA_EVT_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PDA_EVT_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PDA_EVT_TYPE
--  DESCRIPTION : Description d'une property avec principe clé/valeur
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.28 | Hocine HAMMOU
--          | Init Projet [10326] Migration PDA vers WebAPI
--
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION PDA_EVT_TYPE(SELF IN OUT NOCOPY PDA_EVT_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PDA_EVT_TYPE (
                               FILE_PDA_ID          => NULL
                            ,  FILE_PDA_BUILD       => NULL
                            ,  FILE_VERSION         => NULL
                            ,  FILE_DTM             => NULL
                            ,  BO_PARCEL_ID         => NULL
                            ,  PARCEL_KNOWN         => NULL
                            ,  FIRM_ID              => NULL
                            ,  FIRM_PARCEL_ID       => NULL
                            ,  PDA_EVENT_ID         => NULL
                            ,  EVENT_TYPE_ID        => NULL
                            ,  LOCAL_DTM            => NULL
                            ,  PROPERTIES_QTY       => NULL
                            ,  EVENT_PROPERTIES     => NULL
                            );

   RETURN;
END;




 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ea va renvoyer une liste vide) pour un DELIVERY STANDARD
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   -- propriétés qui ont sense pour tous les evenements pickup

   IF TRIM(self.FILE_VERSION) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_VERSION');
   END IF;
   IF TRIM(self.FILE_PDA_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_ID');
   END IF;
   IF TRIM(self.FILE_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_DTM');
   END IF;
   IF TRIM(self.FILE_PDA_BUILD) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_BUILD');
   END IF;
   -- BO_PARCEL_ID peut etre NULL
   -- IF TRIM(self.BO_PARCEL_ID) IS NULL THEN
   --    l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'BO_PARCEL_ID');
   -- END IF;
   IF TRIM(self.PARCEL_KNOWN) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PARCEL_KNOWN');
   END IF;
   IF TRIM(self.FIRM_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FIRM_ID');
   END IF;
   IF TRIM(self.FIRM_PARCEL_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FIRM_PARCEL_ID');
   END IF;
   IF TRIM(self.PDA_EVENT_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PDA_EVENT_ID');
   END IF;
   IF TRIM(self.EVENT_TYPE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'EVENT_TYPE_ID');
   END IF;
   IF TRIM(self.LOCAL_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LOCAL_DTM');
   END IF;
   IF TRIM(self.PROPERTIES_QTY) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PROPERTIES_QTY');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;



END;

/
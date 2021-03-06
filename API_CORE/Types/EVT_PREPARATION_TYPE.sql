CREATE OR REPLACE TYPE api_core."EVT_PREPARATION_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_PREPARATION_TYPE
--  DESCRIPTION : Description des attributs de l'évènement PREPARATION reçu
--                par WEB SERVICES.
--                API_CORE.EVT_PREPARATION_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Maria CASALS
--          | Init
-- ***************************************************************************
( BARCODE                        VARCHAR2(50) -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, CONSTRUCTOR FUNCTION EVT_PREPARATION_TYPE(SELF IN OUT NOCOPY EVT_PREPARATION_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_PREPARATION_TYPE) RETURN VARCHAR2

, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL -- ????

/
CREATE OR REPLACE TYPE BODY api_core."EVT_PREPARATION_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_PREPARATION_TYPE
--  DESCRIPTION : Description des attributs de l'évènement PREPARATION reçu
--                par WEB SERVICES.
--                API_CORE.EVT_PREPARATION_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Maria CASALS
--          | Init
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_PREPARATION_TYPE(SELF IN OUT NOCOPY EVT_PREPARATION_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_PREPARATION_TYPE
      ( FIRM_PARCEL_ID         => NULL
      , BO_PARCEL_ID           => NULL
      , FIRM_ID                => NULL
      , LOCAL_DTM              => NULL
      , INTERNATIONAL_SITE_ID  => NULL
      , BARCODE                => NULL
      );
   return;
END;

-- -----------------------------------------------------------------------------
-- Fonction  : TargetEventType
--    Renvoie le type d'évèenement (exemple : PREPARATION ou PICKUP ou REFUSE ...)
--    ATTENTION, c'est PREPARATION_FOR_COLLECTION, pas IN_PREPARATION, selon acté par PLOP en réunion le 2015.07.10
-- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_PREPARATION_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN PCK_API_CONSTANTS.c_evt_type_PREP_FOR_COLLECTION;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour une PREPARATION
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;



/
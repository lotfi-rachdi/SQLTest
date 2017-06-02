CREATE OR REPLACE TYPE api_core."EVT_SCAN_DROPOFF_TYPE"                                          FORCE UNDER api_core.EVT_DROPOFF_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_SCAN_DROPOFF_TYPE
--  DESCRIPTION : Description des attributs de l'évènement SCAN issu du DROPOFF et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_DROPOFF_TYPE est un sous-type de API_CORE.EVT_DROPOFF_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.08.22 | Hocine HAMMOU
--          | Création - Projet RM3 [10330] DROPOFF Pologne
--          |
--  V01.001 | 2015.09.15 | Hocine HAMMOU
--          | Mise en place de l'héritage de API_CORE.EVT_DROPOFF_TYPE
--          |
--  V01.002 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et DELIVERY_FIRM_PARCEL_ID
-- ***************************************************************************
( FORM                           VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, REASON                         VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, ABANDONED                      NUMBER(1)      -- 2016.12.23

, CONSTRUCTOR FUNCTION EVT_SCAN_DROPOFF_TYPE(SELF IN OUT NOCOPY EVT_SCAN_DROPOFF_TYPE) RETURN SELF AS RESULT
, OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_DROPOFF_TYPE) RETURN VARCHAR2
, OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_SCAN_DROPOFF_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_SCAN_DROPOFF_TYPE
--  DESCRIPTION : Description des attributs de l'évènement SCAN issu du DROPOFF et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_DROPOFF_TYPE est un sous-type de API_CORE.EVT_DROPOFF_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.09 | Hocine HAMMOU
--          | Création - Projet RM3 [10330] DROPOFF Pologne
--          |
--  V01.001 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et DELIVERY_FIRM_PARCEL_ID
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_SCAN_DROPOFF_TYPE(SELF IN OUT NOCOPY EVT_SCAN_DROPOFF_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_SCAN_DROPOFF_TYPE
      ( FIRM_PARCEL_ID          => NULL
      , BO_PARCEL_ID            => NULL
      , FIRM_ID                 => NULL
      , LOCAL_DTM               => NULL
      , INTERNATIONAL_SITE_ID   => NULL
      , BARCODE                 => NULL
      , Q_DAMAGED_PARCEL        => NULL
      , Q_OPEN_PARCEL           => NULL
      , CONSIGNMENT_TYPE        => NULL
      , FIRM_PARCEL_OTHER       => NULL
      , CHECKLIST_MANDATORY     => NULL
      , CHECKLIST               => NULL
      , RECEIPT_NUMBER          => NULL
      , PHONE_NUMBER            => NULL
      , SIGN_DATA               => NULL
      , SWAP                    => NULL
      , DELIVERY_FIRM_PARCEL_ID => NULL
      , ASSOCIATED_CAB2D        => NULL

      , FORM                    => NULL
      , REASON                  => NULL
      , ABANDONED               => NULL
      );
   RETURN;
END;

-- -----------------------------------------------------------------------------
-- Fonction  : TargetEventType
--    Renvoie le type d'évènement (exemple : DROPOFF ou PICKUP ou REFUSE ...)
--
-- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_DROPOFF_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(50);
BEGIN

   -- IF self.ABANDONED = 1 OR self.ASSOCIATED_CAB2D IS NOT NULL THEN
   --    l_result := PCK_API_CONSTANTS.c_evt_type_SCAN_DPL;
   -- ELSE
      l_result := PCK_API_CONSTANTS.c_evt_type_SCAN;
   -- END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour un SCAN DROPOFF
 -- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   IF self.ABANDONED = 1 THEN
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_ABANDONED );
   ELSE
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DAMAGED_PARCEL );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_OPEN_PARCEL );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_FIRM_PARCEL_OTHER );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_NATURE_OF_GOODS );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECEIPT_NUMBER );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_PHONE_NUMBER );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SIGN_DATA );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SWAP );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DELIVERY_FIRM_PARCEL );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_ASSOCIATED_CAB2D ); -- ?? A confirmer ou infimrer vs ABANDONED
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_FORM );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_REASON );
   END IF;

   RETURN l_result;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;



END;

/
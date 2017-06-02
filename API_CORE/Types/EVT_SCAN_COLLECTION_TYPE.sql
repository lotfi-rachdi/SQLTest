CREATE OR REPLACE TYPE api_core."EVT_SCAN_COLLECTION_TYPE"                                          FORCE UNDER api_core.EVT_COLLECTION_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_SCAN_COLLECTION_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement SCAN  issu de la COLLECTION et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_COLLECTION_TYPE est un sous-type de API_CORE.EVT_COLLECTION_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.03.21 | Hocine HAMMOU
--          | Init
--          | Projet RM2 [10302] Transfert de responsabilité en COllection:
--          | Création de l'event SCAN pour traiter les cas ol le CAB2DSTATUS prend dans les cas ol Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          | les valeurs suivantes : CARRIER_LEFT, TERMINAL_CARRIER_KO, REFUSED_COLLECTION_CARRIER, REFUSED_COLLECTION_MERCHANT
--          |
--  V01.000 | 2016.09.15 | Hocine HAMMOU
--          | Projet RM3 [10330] API_CORE.EVT_SCAN_COLLECTION_TYPE hérite des attributs de API_CORE.EVT_COLLECTION_TYPE
--          |
-- ***************************************************************************
( FORM                           VARCHAR2(50) -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, CONSTRUCTOR FUNCTION EVT_SCAN_COLLECTION_TYPE(SELF IN OUT NOCOPY EVT_SCAN_COLLECTION_TYPE) RETURN SELF AS RESULT
, OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_COLLECTION_TYPE) RETURN VARCHAR2
, OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_SCAN_COLLECTION_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_SCAN_COLLECTION_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement SCAN  issu de la COLLECTION et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_COLLECTION_TYPE est un sous-type de API_CORE.EVT_COLLECTION_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.03.21 | Hocine HAMMOU
--          | Init
--          | Projet RM2 [10302] Transfert de responsabilité en COllection:
--          | Création de l'event SCAN pour traiter les cas ol le CAB2DSTATUS prend dans les cas ol Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          | les valeurs suivantes : CARRIER_LEFT, TERMINAL_CARRIER_KO, REFUSED_COLLECTION_CARRIER, REFUSED_COLLECTION_MERCHANT
--          |
--  V01.001 | 2016.09.15 | Hocine HAMMOU
--          | Projet RM3 [10330] API_CORE.EVT_SCAN_COLLECTION_TYPE hérite des attributs de API_CORE.EVT_COLLECTION_TYPE
--          |
--  V01.002 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_SCAN_COLLECTION_TYPE(SELF IN OUT NOCOPY EVT_SCAN_COLLECTION_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_SCAN_COLLECTION_TYPE
      ( FIRM_PARCEL_ID         => NULL
      , BO_PARCEL_ID           => NULL
      , FIRM_ID                => NULL
      , LOCAL_DTM              => NULL
      , INTERNATIONAL_SITE_ID  => NULL
      , BARCODE                => NULL
      , SIGN_DATA              => NULL
      , Q_DAMAGED_PARCEL       => NULL
      , Q_OPEN_PARCEL          => NULL
      , CAB2DKEY               => NULL
      , CAB2DSTATUS            => NULL
      , PHYSICAL_CARRIER_ID    => NULL
      , FORM                   => NULL
      );
   return;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction  : TargetEventType
 --    Renvoie le type d'évcenement (exemple : DELIVERY ou PICKUP ou REFUSE ...)
 -- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_COLLECTION_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN PCK_API_CONSTANTS.c_evt_type_SCAN;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributs en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ea va renvoyer une liste vide) pour un SCAN COLLECTION
 -- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SIGN_DATA );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DAMAGED_PARCEL );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_OPEN_PARCEL );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_CAB2DKEY );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_CAB2DSTATUS );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_PHYSICAL_CARRIER_ID );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_FORM );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/
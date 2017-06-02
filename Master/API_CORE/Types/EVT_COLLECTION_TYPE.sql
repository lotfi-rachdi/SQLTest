CREATE OR REPLACE TYPE api_core."EVT_COLLECTION_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_COLLECTION_TYPE
--  DESCRIPTION : Description des attributs de l'évènement COLLECTION reçu
--                par WEB SERVICES.
--                API_CORE.EVT_COLLECTION_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.29 | Amadou YOUNSAH
--          | Init
--
--  V01.100 | 2016.01.25 | Hocine HAMMOU
--          | [10163] LOT2 INDE : Modification de la longuer du champ SIGN_DATA à 3000 car.
--          | comme la colonne MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE (au lieu de 4000)
--
--  V01.100 | 2016.02.03 | Hocine HAMMOU
--          | [10163] RM1 LOT2 INDE : Ajout des réserves -> Q_DAMAGED_PARCEL
--          |                                            -> Q_OPEN_PARCEL
--          |
--  V01.101 | 2016.03.21 | Hocine HAMMOU
--          | projet RM2 [10302] Transfert de responsabilité :
--          | Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          |
--  V01.102 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- ***************************************************************************
( BARCODE                        VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, SIGN_DATA                      VARCHAR2(3000) -- used as INPUT colum, optional -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE / MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE
, Q_DAMAGED_PARCEL               NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_DAMAGED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, Q_OPEN_PARCEL                  NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_OPENNED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, CAB2DKEY                       VARCHAR2(50)   -- 2016.03.21 projet [10302] --  used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, CAB2DSTATUS                    VARCHAR2(50)   -- 2016.03.21 projet [10302] --  used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, PHYSICAL_CARRIER_ID            VARCHAR2(50)   -- 2016.11.07 projet [10472]
, CONSTRUCTOR FUNCTION EVT_COLLECTION_TYPE(SELF IN OUT NOCOPY EVT_COLLECTION_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_COLLECTION_TYPE) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_COLLECTION_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_COLLECTION_TYPE
--  DESCRIPTION : Description des attributs de l'évènement COLLECTION reçu
--                par WEB SERVICES.
--                API_CORE.EVT_COLLECTION_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.28 | Amadou YOUNSAH
--          | Init
--
--  V01.100 | 2016.02.03 | Hocine HAMMOU
--          | [10163] RM1 LOT2 INDE : Ajout des réserves -> Q_DAMAGED_PARCEL
--          |                                            -> Q_OPEN_PARCEL
--          |
--  V01.101 | 2016.03.21 | Hocine HAMMOU
--          | projet [10302] Transfert de responsabilité :
--          | Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          |
--  V01.102 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_COLLECTION_TYPE(SELF IN OUT NOCOPY EVT_COLLECTION_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_COLLECTION_TYPE
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
      );
   RETURN;
END;

-- -----------------------------------------------------------------------------
-- Fonction  : TargetEventType
--    Renvoie le type d'évèenement (exemple : COLLECTION ou PICKUP ou REFUSE ...)
--    ATTENTION, c'est COLLECTION_FOR_COLLECTION, pas IN_COLLECTION, selon acté par PLOP en réunion le 2015.07.10
-- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_COLLECTION_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN PCK_API_CONSTANTS.c_evt_type_COLLECTION;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour une COLLECTION
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
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

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/
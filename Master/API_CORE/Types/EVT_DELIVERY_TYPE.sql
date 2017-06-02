CREATE OR REPLACE TYPE api_core."EVT_DELIVERY_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_DELIVERY_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement DELIVERY reçu
--                par WEB SERVICES.
--                API_CORE.EVT_DELIVERY_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.23 | Maria CASALS
--          | Init
--  V01.100 | 2015.06.24 | Maria CASALS0
--          | Les colonnes DURATION et FORM disparaissent
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          |
--  V01.200 | 2015.07.08 | Hocine HAMMOU
--          | Ajout de la fonction MissingMandatoryAttributes qui
--          | permet de vérifier la présence des valeurs obligatoires
--          |
--  V01.201 | 2016.03.21 | Hocine HAMMOU
--          | projet RM2 [10302] Transfert de responsabilité :
--          | Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          |
--  V01.203 | 2016.11.02 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
--          |
-- ***************************************************************************
( BARCODE                        VARCHAR2(50) -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
-- 2015.06.24 disparait -- DURATION                       INTEGER      -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, Q_DAMAGED_PARCEL               NUMBER(1)    -- used as INPUT column -- FLAG: if 1 a row for Q_DAMAGED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, Q_OPEN_PARCEL                  NUMBER(1)    -- used as INPUT column -- FLAG: if 1 a row for Q_OPENNED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
-- 2015.06.24 disparait -- , FORM                           VARCHAR2(50) -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, CAB2DKEY                       VARCHAR2(50) -- 2016.03.21 projet [10302] --  used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, CAB2DSTATUS                    VARCHAR2(50) -- 2016.03.21 projet [10302] --  used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, PHYSICAL_CARRIER_ID            VARCHAR2(50) -- 2016.11.02 projet [10472]
, CONSTRUCTOR FUNCTION EVT_DELIVERY_TYPE(SELF IN OUT NOCOPY EVT_DELIVERY_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_DELIVERY_TYPE) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_DELIVERY_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_DELIVERY_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement DELIVERY reçu
--                par WEB SERVICES.
--                API_CORE.EVT_DELIVERY_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Maria CASALS
--          | Init
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Les colonnes EVENT_ID et PARCEL_KNOWN disparaissent
--          | Les colonnes DURATION et FORM disparaissent
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          |
--  V01.200 | 2015.07.08 | Hocine HAMMOU
--          | Ajout de la fonction MissingMandatoryAttributes qui
--          | permet de vérifier la présence des valeurs obligatoires
--          |
--  V01.300 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.301 | 2016.03.21 | Hocine HAMMOU
--          | projet [10302] Transfert de responsabilité :
--          | Ajout des attributs CAB2DKEY et CAB2DSTATUS
--          |
--  V01.302 | 2016.11.02 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_DELIVERY_TYPE(SELF IN OUT NOCOPY EVT_DELIVERY_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_DELIVERY_TYPE
      ( -- 2015.06.24 disparait -- EVENT_ID          => NULL
        FIRM_PARCEL_ID         => NULL
      , BO_PARCEL_ID           => NULL
      , FIRM_ID                => NULL
      -- 2015.06.24 disparait -- , PARCEL_KNOWN      => NULL
      , LOCAL_DTM              => NULL
      -- 2015-07-10 remplacé  -- , SITE_ID           => NULL
      , INTERNATIONAL_SITE_ID  => NULL
      , BARCODE                => NULL
      -- 2015.06.24 disparait --, DURATION           => NULL
      , Q_DAMAGED_PARCEL       => NULL
      , Q_OPEN_PARCEL          => NULL
      -- 2015.06.24 disparait --, FORM               => NULL
      , CAB2DKEY               => NULL               -- 2016.03.21 projet [10302]
      , CAB2DSTATUS            => NULL               -- 2016.03.21 projet [10302]
      , PHYSICAL_CARRIER_ID    => NULL               -- 2016.11.02 projet [10472]
      );
   return;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction  : TargetEventType
 --    Renvoie le type d'évèenement (exemple : DELIVERY ou PICKUP ou REFUSE ...)
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_DELIVERY_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN PCK_API_CONSTANTS.c_evt_type_DELIVERY;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour un DELIVERY STANDARD
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
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
CREATE OR REPLACE TYPE api_core."EVT_SCAN_PICKUP_TYPE"                                          FORCE UNDER api_core.EVT_PICKUP_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_SCAN_PICKUP_TYPE
--  DESCRIPTION : Description des attributs de l'évènement SCAN issu du PICKUP et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_PICKUP_TYPE est un sous-type de API_CORE.EVT_PICKUP_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.09 | Hocine HAMMOU
--          | Création - Projet RM3 [10330] Event SCAN pour le PICKUP
--          |
--  V01.001 | 2015.11.16 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP UK - Ajout propriété IDENTITY_VERIFICATION_2
--          |
--  V01.002 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et RETURN_FIRM_PARCEL_ID
-- ***************************************************************************
( FORM                           VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE

, CONSTRUCTOR FUNCTION EVT_SCAN_PICKUP_TYPE(SELF IN OUT NOCOPY EVT_SCAN_PICKUP_TYPE) RETURN SELF AS RESULT
, OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_PICKUP_TYPE) RETURN VARCHAR2
, OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_SCAN_PICKUP_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_SCAN_PICKUP_TYPE
--  DESCRIPTION : Description des attributs de l'évènement SCAN issu du PICKUP et reçu donc via les WEB SERVICES.
--                API_CORE.EVT_SCAN_PICKUP_TYPE est un sous-type de API_CORE.EVT_PICKUP_TYPE qui est lui meme un sous-type de API_CORE.EVT_TYPE
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.09 | Hocine HAMMOU
--          | Création - Projet RM3 [10330] Event SCAN pour le PICKUP
--          |
--  V01.001 | 2015.11.16 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP UK - Ajout propriété IDENTITY_VERIFICATION_2
--          |
--  V01.002 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et RETURN_FIRM_PARCEL_ID
-- ***************************************************************************
IS

CONSTRUCTOR FUNCTION EVT_SCAN_PICKUP_TYPE(SELF IN OUT NOCOPY EVT_SCAN_PICKUP_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_SCAN_PICKUP_TYPE( FIRM_PARCEL_ID           => NULL
                               , BO_PARCEL_ID             => NULL
                               , FIRM_ID                  => NULL
                               , LOCAL_DTM                => NULL
                               , INTERNATIONAL_SITE_ID    => NULL
                               , BARCODE                  => NULL
                               , DURATION                 => NULL
                               , SIGN_DATA                => NULL
                               , Q_DAMAGED_PARCEL         => NULL
                               , Q_OPEN_PARCEL            => NULL
                               , CDC_CODE                 => NULL
                               , NAME_OF_RECIPIENT        => NULL
                               , IDENTITY_VERIFICATION    => NULL
                               , ID_RECORD                => NULL
                               , COD_AMOUNT_PAID          => NULL
                               , COD_CURRENCY             => NULL
                               , COD_MEANS_PAYMENT_ID     => NULL
                               , Id_Type                  => NULL
                               , Payment_Type             => NULL
                               , Refuse_Type              => NULL
                               , REASON                   => NULL
                               , RECEIVER_TYPE_MANDATORY  => NULL
                               , RECEIVER_TYPE            => NULL
                               , IDENTITY_VERIFICATION_2  => NULL
                               , SWAP                     => NULL
                               , RETURN_FIRM_PARCEL_ID    => NULL
                               , FORM                     => 'PICKUP'
                               );

   RETURN;
END;

-- -----------------------------------------------------------------------------
-- Fonction  : TargetEventType
--    Renvoie le type d'évènement (exemple : PICKUP ou PICKUP ou REFUSE ...)
-- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION TargetEventType (self in EVT_SCAN_PICKUP_TYPE) RETURN VARCHAR2
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
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour un SCAN PICKUP
 -- -----------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DURATION );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SIGN_DATA);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DAMAGED_PARCEL);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_OPEN_PARCEL);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_CDC_CODE);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECIPIENT_NAME);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_ID_RECORD);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_AMOUNT_PAID);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_CURRENCY);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_MEANS_PAYMENT_ID);
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_REASON );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECEIVER_TYPE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF_2);    -- 2015.11.16  [10472]
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SWAP );               -- 2015.11.25  [10472]
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RETURN_FIRM_PARCEL ); -- 2015.11.25  [10472]

   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_FORM );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/
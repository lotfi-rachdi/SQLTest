CREATE OR REPLACE TYPE api_core."EVT_DROPOFF_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_DROPOFF_TYPE
--  DESCRIPTION : Description des attributs de l'évènement DROPOFF reçu
--                par WEB SERVICES.
--                API_CORE.EVT_DROPOFF_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.31 | Amadou YOUNSAH
--          | Init
--
--  V01.010 | 2015.11.13 | Hocine HAMMOU
--          | LOT2 INDE - Ajout du champ CHECKLIST : champ de saisie libre pour consigner
--          | le contenu du colis dans le champ CHECKLIST( Evolution LOT2 INDE)
--          |
--  V01.011 | 2016.08.17 | Hocine HAMMOU
--          | Projet RM3 [10330] Application Hybride Android V3
--          | Ajout des proprietes RECEIPT_NUMBER (alias le TRACKING NUMBER) et PHONE_NUMBER, et SIGN_DATA
--          |
--  V01.012 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP, DELIVERY_FIRM_PARCEL_ID, ASSOCIATED_CAB2D
-- ***************************************************************************
( BARCODE                        VARCHAR2(50) -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, Q_DAMAGED_PARCEL               NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_DAMAGED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, Q_OPEN_PARCEL                  NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_OPENNED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, CONSIGNMENT_TYPE               NUMBER(1)
, FIRM_PARCEL_OTHER              VARCHAR2(50)
, CHECKLIST_MANDATORY            NUMBER(1)      -- Values : 0 => CHECKLIST IS NOT MANDATORY ; 1 => CHECKLIST IS MANDATORY  -- 2015/11/13 LOT2 INDE
, CHECKLIST                      VARCHAR2(200)  -- is NATURE OF GOODS of parcel -- 2015/11/13 LOT2 INDE
, RECEIPT_NUMBER                 VARCHAR2(100)  -- 2016.08.17
, PHONE_NUMBER                   VARCHAR2(30)   -- 2016.08.17
, SIGN_DATA                      VARCHAR2(4000) -- 2016.08.29
, SWAP                           NUMBER(1)      -- VARCHAR2(50)    --  2016.11.25 -- SWAP : propriété si = 1 alors contexte SWAP , si = 0 pas de contexte SWAP
, DELIVERY_FIRM_PARCEL_ID        VARCHAR2(50)   -- 2016.11.25
, ASSOCIATED_CAB2D               VARCHAR2(50)   -- 2016.12.22

, CONSTRUCTOR FUNCTION EVT_DROPOFF_TYPE(SELF IN OUT NOCOPY EVT_DROPOFF_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_DROPOFF_TYPE) RETURN VARCHAR2

, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_ConsignType(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_CheckList(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_SWAP (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_CAB2D (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_DROPOFF_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_DROPOFF_TYPE
--  DESCRIPTION : Description des attributs de l'évènement DROPOFF reçu
--                par WEB SERVICES.
--                API_CORE.EVT_DROPOFF_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.31 | Amadou YOUNSAH
--          | Init
--  V01.010 | 2015.11.13 | Hocine HAMMOU
--          | Ajout du champ CHECKLIST : champ de saisie libre pour consigner
--          | le contenu du colis ( Evolution LOT2 INDE)
--  V01.011 | 2016.08.19 | Hocine HAMMOU
--          | Projet RM3 [10330] Application Hybride Android V3
--          | Ajout des proprietes RECEIPT_NUMBER (alias le TRACKING NUMBER) et PHONE_NUMBER
--  V01.012 | 2016.11.15 | Hocine HAMMOU
--          | BUG#65585 : envoi de la propriété SIGN_DATA dans le BO
--  V01.013 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP, DELIVERY_FIRM_PARCEL_ID, ASSOCIATED_CAB2D
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_DROPOFF_TYPE(SELF IN OUT NOCOPY EVT_DROPOFF_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_DROPOFF_TYPE
      ( FIRM_PARCEL_ID           => NULL
      , BO_PARCEL_ID             => NULL
      , FIRM_ID                  => NULL
      , LOCAL_DTM                => NULL
      , INTERNATIONAL_SITE_ID    => NULL
      , BARCODE                  => NULL
      , Q_DAMAGED_PARCEL         => NULL
      , Q_OPEN_PARCEL            => NULL
      , CONSIGNMENT_TYPE         => NULL
      , FIRM_PARCEL_OTHER        => NULL
      , CHECKLIST_MANDATORY      => NULL  -- 2015/11/13 LOT2 INDE
      , CHECKLIST                => NULL  -- 2015/11/13 LOT2 INDE : corresponding to the 'NATURE OF GOODS'
      , RECEIPT_NUMBER           => NULL  -- 2016.08.19 [10330]
      , PHONE_NUMBER             => NULL  -- 2016.08.19 [10330]
      , SIGN_DATA                => NULL  -- 2016.08.29 [10330]
      , SWAP                     => NULL  -- 2016.11.25 [10472]
      , DELIVERY_FIRM_PARCEL_ID  => NULL  -- 2016.11.25 [10472]
      , ASSOCIATED_CAB2D         => NULL  -- 2016.12.22 [10472]
      );
   return;
END;

-- -----------------------------------------------------------------------------
-- Fonction  : TargetEventType
--    Renvoie le type d'évèenement (exemple : DROPOFF ou PICKUP ou REFUSE ...)
--    ATTENTION, c'est DROPOFF_FOR_DROPOFF, pas IN_DROPOFF, selon acté par PLOP en réunion le 2015.07.10
-- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_DROPOFF_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN PCK_API_CONSTANTS.c_evt_type_DROPOFF;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour une DROPOFF
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
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECEIPT_NUMBER ); -- BUG#65585
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_PHONE_NUMBER );   -- BUG#65585
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SIGN_DATA );      -- BUG#65585

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_ConsignType :
 --  Values 0 => NONE ; 1 => WITH FIRM_PARCEL_OTHER
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires pour le CONSIGNMENT_TYPE
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_ConsignType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_ConsignType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
--  Values 0 => NONE ; 1 => WITH FIRM_PARCEL_OTHER
   IF CONSIGNMENT_TYPE IS NULL THEN
        l_result:= NULL;
   ELSIF CONSIGNMENT_TYPE = 0 THEN
        l_result:= NULL;
   ELSIF CONSIGNMENT_TYPE = 1 THEN
      IF FIRM_PARCEL_OTHER IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FIRM_PARCEL_OTHER');
      END IF;

     -- in this case, the properties make sense
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_FIRM_PARCEL_OTHER );
   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - CONSIGNMENT_TYPE : ' || CONSIGNMENT_TYPE);
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_CheckList :
 --  Values 0 => NO CHECKLIST ; 1 => WITH CHECKLIST
 --  Vérifie le caractère obligatoire ou non du champ CheckList
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_CheckList (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_CheckList';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF CHECKLIST_MANDATORY IS NULL THEN -- Champ CHECKLIST NON obligatoire
        l_result:= NULL;
   ELSIF CHECKLIST_MANDATORY = 0 THEN -- Champ CHECKLIST NON obligatoire
        l_result:= NULL;
   ELSIF CHECKLIST_MANDATORY = 1 THEN -- Champ CHECKLIST OBLIGATOIRE
      IF TRIM(CHECKLIST) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NATURE_OF_GOODS');
      END IF;
     -- in this case, the properties make sense
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_NATURE_OF_GOODS );
   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - CHECKLIST_MANDATORY : ' || CHECKLIST_MANDATORY);
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_SWAP :
 --  Renvoie la liste d'attributs en erreur parce qu'indispensables dans les prestations ECHANGES
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_SWAP (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_SWAP';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SWAP );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DELIVERY_FIRM_PARCEL );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_CAB2D :
 --  Renvoie la liste d'attributs en erreur parce qu'indispensables dans les prestations ECHANGES
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_CAB2D (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_CAB2D';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_ASSOCIATED_CAB2D );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/
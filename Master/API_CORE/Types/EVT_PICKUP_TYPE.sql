CREATE OR REPLACE TYPE api_core."EVT_PICKUP_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_PICKUP_TYPE
--  DESCRIPTION : Description des attibuts de l'évcnement PICKUP ou REFUSE reeu
--                par WEB SERVICES.
--                API_CORE.EVT_PICKUP_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.23 | Maria CASALS + Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Q_OPENNED_PARCEL renommé a Q_OPEN_PARCEL
--          |
--  V01.200 | 2015.06.26 | Maria CASALS
--          | FORM disparait ainsi que REASON
--          |
--  V01.300 | 2015.07.08 | Hocine HAMMOU
--          | Ajout de la fonction MissingMandatoryAttributes qui
--          | permet de vérifier la présence des valeurs obligatoires
--          |
--  V01.400 | 2015.07.15 | Hocine HAMMOU
--          | Ajout des fonctionnalités EASY PINCODE + COD ( Cash On Delivery)
--          |
--  V01.410 | 2015.07.17 | Hocine HAMMOU
--          | unification avec les team WEB API et WEB APP : ajout de flags
--          | dans le message pour mieux identifier :
--          |  - l'évcnement REFUSE ( suite a la suppression EVT_REFUSE_TYPE : a confirmer)
--          |  - le cas du pickup avec pincode
--          |  - le cas du pickup avec présentation de la identity card
--          |  - le cas du pickup avec C.O.D.
--          |
--  V01.501 | 2015.07.17 | Maria CASALS
--          | rajout paramctre p_relevant_properties
--
--  V01.502 | 2015.11.16 | Hocine HAMMOU
--          | LOT2 INDE : Ajout attributs pour gérer lle lien de parenté avec le bénéficiaire du colis
--          | La propriété Lien de parenté est a renseigner uniquement dans le cas ol Pickup sans Pincode
--
--  V01.503 | 2016.06.24 | Hocine HAMMOU
--          | Projet [10302] Modif. de la longueur du champ ID_RECORD de 5 a 100car.
--          |
--  V01.504 | 2016.08.24 | Hocine HAMMOU
--          | Projet [10330] Evolution PICKUP - Ajout possibilité supplémentaire #3 dans l'enum Id_Type
--          | 2016.09.01
--          | Projet [10330] Evolution PICKUP - Ajout possibilité supplémentaire #4 dans l'enum Id_Type
--          |
--  V01.505 | 2016.11.16 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP UK - Ajout propriété IDENTITY_VERIFICATION_2
--          |
--  V01.506 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et RETURN_FIRM_PARCEL_ID
--          |
-- *******************************************************************************************************
( BARCODE                        VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, DURATION                       INTEGER        -- used as INPUT column, ce sont les secondes -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, SIGN_DATA                      VARCHAR2(4000) -- used as INPUT colum, optional -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
, Q_DAMAGED_PARCEL               NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_DAMAGED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
, Q_OPEN_PARCEL                  NUMBER(1)      -- used as INPUT column -- FLAG: if 1 a row for Q_OPENNED_PARCEL property will be added to IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED, otherwise not
-- 2015.06.26 disparait -- , FORM                           VARCHAR2(50)   -- used as INPUT column -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE
-- 2015.06.26 ceci est pour le REFUSE -- , REASON                         VARCHAR2(50)   -- used as INPUT column -> -> IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE

-- 2015.13.07 PICKUP INDE : EASY PINCODE + COD
-- ?? doit-on controler le type de donnée attendue pour chacune des valeurs , ou bien type-t-on directement les données en VARCHAR2  ??

, Id_Type                       INTEGER            -- Values 0 => NONE ; 1 => WITH PINCODE ; 2 => WITH ID CARD ; 3  => WITH PINCODE/BARCODE
, CDC_CODE                      VARCHAR2(20)       -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE
, NAME_OF_RECIPIENT             VARCHAR2(151)      -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE  VARCHAR2(3000)
, IDENTITY_VERIFICATION         VARCHAR2(50)       -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE  VARCHAR2(3000)
, ID_RECORD                     VARCHAR2(100)      -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE  VARCHAR2(3000)

, Payment_Type                  INTEGER            --  Values 0 => NONE ; 1 => WITH COD (Cash On Delivery)
, COD_AMOUNT_PAID               NUMBER(15,3)       -- value stored in MASTER.PARCEL.COD_AMOUNT
, COD_CURRENCY                  VARCHAR2(3)        -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE  VARCHAR2(3000)
, COD_MEANS_PAYMENT_ID          VARCHAR2(20)       -- to store in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE ??

, Refuse_Type                   INTEGER            --  Values 0 => NO REFUSAL ; 1 => REFUSAL EVENT, REASON IS NOT MANDATORY ; 2 => REFUSAL EVENT, REASON IS MANDATORY
, REASON                        VARCHAR2(50)       --  REFUSAL REASON, value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE

-- 20151117 LOT 2 INDE : Lien de parenté
, RECEIVER_TYPE_MANDATORY       NUMBER(1)          --  Values 0 => NO RECEIVER_TYPE ; 1 => WITH RECEIVER_TYPE
, RECEIVER_TYPE                 VARCHAR2(50)       --  RECEIVER_TYPE , values stored in CONFIG.RECEIVER_TYPE
, IDENTITY_VERIFICATION_2       VARCHAR2(50)       -- value stored in MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE  VARCHAR2(3000)

, SWAP                          NUMBER(1) --VARCHAR2(50)       --  2016.11.25 -- SWAP : propriété si = 1 alors contexte SWAP , si = 0 pas de contexte SWAP
, RETURN_FIRM_PARCEL_ID         VARCHAR2(50)       --  2016.11.25

, CONSTRUCTOR FUNCTION EVT_PICKUP_TYPE(SELF IN OUT NOCOPY EVT_PICKUP_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_PICKUP_TYPE) RETURN VARCHAR2

, MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_IDType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_PaymentType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_RefuseType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_ReceiverType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandAttrs_SWAP (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_PICKUP_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_PICKUP_TYPE
--  DESCRIPTION : Description des attibuts de l'évcnement PICKUP ou REFUSE reeu
--                par WEB SERVICES.
--                API_CORE.EVT_PICKUP_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.23 | Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Les colonnes EVENT_ID et PARCEL_KNOWN disparaissent
--          | Q_OPENNED_PARCEL renommé a Q_OPEN_PARCEL
--          |
--  V01.200 | 2015.06.26 | Maria CASALS
--          | FORM disparait ainsi que REASON
--          |
--  V01.300 | 2015.07.08 | Hocine HAMMOU
--          | Ajout de la fonction MissingMandatoryAttributes qui
--          | permet de vérifier la présence des valeurs obligatoires
--          |
--  V01.400 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.500 | 2015.07.15 | Hocine HAMMOU
--          | Ajout des fonctionnalités EASY PINCODE + COD ( Cash On Delivery)
--          |
--  V01.501 | 2015.07.17 | Maria CASALS
--          | Suppression des fonctions ATTLIST, appel a la place a PCK_API_TOOLS.LIST
--          | rajout paramctre p_relevant_properties
--          |
--  V01.502 | 2015.11.16 | Hocine HAMMOU
--          | LOT2 INDE : Ajout attributs pour gérer lle lien de parenté avec le bénéficiaire du colis
--          | La propriété Lien de parenté est a renseigner uniquement dans le cas ol Pickup sans Pincode
--          |
--  V01.503 | 2016.08.24 | Hocine HAMMOU
--          | Projet [10330] Evolution PICKUP - Ajout possibilité supplémentaire #3 dans l'enum Id_Type
--          | 2016.09.01
--          | Projet [10330] Evolution PICKUP - Ajout possibilité supplémentaire #4 dans l'enum Id_Type
--          |
--  V01.504 | 2016.09.23 | Hocine HAMMOU
--          | Projet [10330] Décomissionnement du controle sur l'ID RECORD
--          |
--  V01.505 | 2016.11.16 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP UK - Ajout propriété IDENTITY_VERIFICATION_2
--          |
--  V01.505 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP et RETURN_FIRM_PARCEL_ID
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_PICKUP_TYPE(SELF IN OUT NOCOPY EVT_PICKUP_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_PICKUP_TYPE
      ( -- 2015.06.24 disparait -- EVENT_ID           => NULL
        FIRM_PARCEL_ID          => NULL
      , BO_PARCEL_ID            => NULL
      , FIRM_ID                 => NULL
      -- 2015.06.24 disparait -- , PARCEL_KNOWN       => NULL
      , LOCAL_DTM               => NULL
      -- 2015.07.10 remplacé  -- , SITE_ID            => NULL
      , INTERNATIONAL_SITE_ID   => NULL
      , BARCODE                 => NULL
      , DURATION                => NULL  --  ????Les colonnes DURATION et FORM disparaissent comme pour DELIVERY???
      , SIGN_DATA               => NULL
      , Q_DAMAGED_PARCEL        => NULL
      , Q_OPEN_PARCEL           => NULL
      -- 2015.06.26 disparait -- , FORM               => NULL  --  ????Les colonnes DURATION et FORM disparaissent comme pour DELIVERY???
      -- 2015.06.26 ceci est pour le REFUSE -- , REASON             => NULL

      -- 2015.07.15 ajout des données EASY PINCODE + COD
      , CDC_CODE                => NULL
      , NAME_OF_RECIPIENT       => NULL
      , IDENTITY_VERIFICATION   => NULL
      , ID_RECORD               => NULL
      , COD_AMOUNT_PAID         => NULL
      , COD_CURRENCY            => NULL
      , COD_MEANS_PAYMENT_ID    => NULL
      , Id_Type                 => NULL
      , Payment_Type            => NULL
      , Refuse_Type             => NULL
      , REASON                  => NULL
      , RECEIVER_TYPE_MANDATORY => NULL
      , RECEIVER_TYPE           => NULL
      , IDENTITY_VERIFICATION_2 => NULL
      , SWAP                    => NULL
      , RETURN_FIRM_PARCEL_ID   => NULL
      );
   RETURN;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction  : TargetEventType
 --    Renvoie le type d'évcenement (exemple : DELIVERY ou PICKUP ou REFUSE ...)
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_PICKUP_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
   --  Values 0 => NO REFUSAL ; 1 => REFUSAL EVENT, REASON IS NOT MANDATORY ; 2 => REFUSAL EVENT, REASON IS MANDATORY
   IF Refuse_Type IS NULL OR Refuse_Type = 0 THEN
      l_result := PCK_API_CONSTANTS.c_evt_type_PICKUP;
   ELSE
      l_result := PCK_API_CONSTANTS.c_evt_type_REFUSE;
   END IF;
   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ea va renvoyer une liste vide) pour un PICKUP STANDARD
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   -- propriétés qui ont sense pour tous les evenements pickup
   -- pour tous les evenements? a monter au type API_CORE.EVT_TYPE ???
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DURATION );
   -- SIGN_DATA partout ou seulement si type identification standard???
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_SIGN_DATA );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_DAMAGED_PARCEL );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_OPEN_PARCEL );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_IDType :
 --    Values 0 => NONE
 --           1 => WITH PINCODE
 --           2 => WITH ID CARD
 --           3 => WITH PINCODE AND RECIPIENT NAME
 --           4 => WITH RECIPIENT NAME
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires pour le ID_TYPE
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_IDType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_IDType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
  -- Values 0 => NONE ; 1 => WITH PINCODE ; 2 => WITH ID CARD ;3 => WITH PINCODE AND RECIPIENT NAME ; 4 => WITH RECIPIENT NAME
   IF Id_Type IS NULL THEN
        l_result:= NULL;
   ELSIF Id_Type = 0 THEN
        l_result:= NULL;
   ELSIF Id_Type = 1 THEN
      IF TRIM(CDC_CODE) IS NULL THEN
        l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'CDC_CODE');
      END IF;
      -- properties that make sense
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_CDC_CODE );
   ELSIF Id_Type = 2 THEN
      -- 2016.12.19 Projet [10472] Décomissionnement du controle sur NAME_OF_RECIPIENT
      -- 2016.12.19 IF TRIM(NAME_OF_RECIPIENT) IS NULL THEN
      -- 2016.12.19    l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NAME_OF_RECIPIENT');
      -- 2016.12.19 END IF;
      IF TRIM(IDENTITY_VERIFICATION) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'IDENTITY_VERIFICATION' );
      END IF;
      -- 2016.09.23 Projet [10330] Décomissionnement du controle sur l'ID RECORD
      -- 2016.09.23 IF TRIM(ID_RECORD) IS NULL THEN
      -- 2016.09.23    l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'ID_RECORD' );
      -- 2016.09.23 END IF;

      -- properties that make sense
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECIPIENT_NAME );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_ID_RECORD );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF_2 ); -- 2016.11.16 [10472]

   ELSIF Id_Type = 3 THEN -- 3 => WITH PINCODE AND RECIPIENT NAME  -- 2016.08.24
      IF TRIM(CDC_CODE) IS NULL THEN
        l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'CDC_CODE');
      END IF;
      IF TRIM(NAME_OF_RECIPIENT) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NAME_OF_RECIPIENT');
      END IF;

      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_CDC_CODE );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECIPIENT_NAME );
   ELSIF Id_Type = 4 THEN -- 4 => WITH RECIPIENT NAME  -- 2016.09.01
      IF TRIM(NAME_OF_RECIPIENT) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NAME_OF_RECIPIENT');
      END IF;
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECIPIENT_NAME );


   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - ID_TYPE : ' || ID_TYPE);
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;



 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_PaymentType :
 --  Values 0 => NONE ; 1 => WITH COD (Cash On Delivery)
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires pour le Payment Type
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_PaymentType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_PaymentType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
--  Values 0 => NONE ; 1 => WITH COD (Cash On Delivery)
   IF Payment_Type IS NULL THEN
        l_result:= NULL;
   ELSIF Payment_Type = 0 THEN
        l_result:= NULL;
   ELSIF Payment_Type = 1 THEN
      IF COD_AMOUNT_PAID IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'COD_AMOUNT_PAID');
      END IF;
      IF TRIM(COD_CURRENCY) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'COD_CURRENCY');
      END IF;
      IF TRIM(COD_MEANS_PAYMENT_ID) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'COD_MEANS_PAYMENT_ID');
      END IF;
      -- in this case, the properties make sense
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_AMOUNT_PAID );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_CURRENCY );
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_COD_MEANS_PAYMENT_ID );
   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - PAYMENT_TYPE : ' || Payment_Type);
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_RefuseType :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires pour le Refuse Type = 1
 --  Values 0 => NO REFUSAL ; 1 => REFUSAL EVENT, REASON IS NOT MANDATORY ; 2 => REFUSAL EVENT, REASON IS MANDATORY
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_RefuseType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_RefuseType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
--  Values 0 => NO REFUSAL ; 1 => REFUSAL EVENT, REASON IS NOT MANDATORY ; 2 => REFUSAL EVENT, REASON IS MANDATORY
--  Refuse_Type
   IF Refuse_Type IS NULL THEN
        l_result:= NULL;
   ELSIF Refuse_Type = 0 THEN
      l_result:= NULL;
   ELSIF Refuse_Type = 1 THEN
        l_result:= NULL;
   ELSIF Refuse_Type = 2 THEN
      IF TRIM(REASON) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'REASON');

      END IF;
   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - REFUSE_TYPE : ' || Refuse_Type);
   END IF;

   -- except if it is not a refusal, REASON property makes sense (mandatory or not)
   IF  Refuse_Type in (0, 1, 2) THEN
      p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_REASON );
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandAttrs_ReceiverType :
 --  Renvoie la liste d'attributs en erreur parce qu'obligatoires pour le Receiver Type = 1
 --  Values 0 => NO RECEIVER_TYPE ; 1 => RECEIVER_TYPE MANDATORY
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandAttrs_ReceiverType (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandAttrs_ReceiverType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
--  Values 0 => NONE ; 1 => RECEIVER_TYPE IS MANDATORY
--  Receiver_Type
   IF RECEIVER_TYPE_MANDATORY IS NULL THEN
        l_result:= NULL;
   ELSIF RECEIVER_TYPE_MANDATORY = 0 THEN
      l_result:= NULL;
   ELSIF RECEIVER_TYPE_MANDATORY = 1 THEN
      IF TRIM(RECEIVER_TYPE) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'RECEIVER_TYPE');
      END IF;
   ELSE
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || ' - RECEIVER_TYPE_MANDATORY : ' || RECEIVER_TYPE_MANDATORY);
   END IF;

   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RECEIVER_TYPE );

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
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_RETURN_FIRM_PARCEL );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

END;

/
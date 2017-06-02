CREATE OR REPLACE TYPE api_core."PARCEL_INFO_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PARCEL_INFO_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement INFO COLIS
--                du fichier reçu par WEB SERVICES.
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          | BO_PARCEL_ID et SITE_ID deviennent INTEGER
--          | MAPPED_PARCEL_STATE_DTM passe à DATE et sera converti à l'heure locale du SITE
--          |
--  V01.200 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.201 | 2016.11.24 | Hocine HAMMOU
--          | Ajout du tableau de parcel properties
--          |
--  V01.202 | 2016.12.21 | Hocine HAMMOU
--          | Ajout des données relatives à la fonctionnalité Payment Summary
-- ***************************************************************************
( FIRM_PARCEL_ID               VARCHAR2(50)                      -- MASTER.PARCEL.FIRM_PARCEL_CARRIER%TYPE
, FIRM_ID                      VARCHAR2(50)                      -- CONFIG.CARRIER.CARRIER_NAME%TYPE
, BO_PARCEL_ID                 INTEGER                           -- MASTER.PARCEL.PARCEL_ID%TYPE
, CREATOR                      VARCHAR2(10)                      -- INITITALISE AVEC LA VEUR 'BO' POUR BACK OFFICE
, KEEPING_PERIOD               INTEGER                           -- PERIOD OF KEEPING IN DAYS
, INTERNATIONAL_SITE_ID        VARCHAR2(35)                      -- MASTER.SITE.SITE_ID%TYPE DEDUIT A PARTIR DES 4 COLONNES SITE_ID DE lA TABLE MASTER.PARCEL
, CODAMOUNT                    NUMBER(15,3)                      -- MASTER.PARCEL.COD_AMOUNT%TYPE
, CUSTOMER_NAME                VARCHAR2(151)                     -- MASTER.PARCEL.SHIPTO_LASTNAME%TYPE + SHIPTO_FIRSTNAME
, SHIPPING_DTM                 DATE                              -- MASTER.PARCEL_EXTEND.SHIPPING_DTM%TYPE
, MAPPED_PARCEL_STATE          VARCHAR2(30)                      -- FONCTION DE MASTER.PARCEL.CURRENT_STEP_ID ET AUTRE CHOSE
, MAPPED_PARCEL_STATE_DTM      DATE                              -- MASTER.PARCEL.CURRENT_STATE_DTM
, Q_DAMAGED_PARCEL             NUMBER(1)                         -- FLAG = 1 alors la PROPRIETE EXISTE sinon 0
, Q_OPEN_PARCEL                NUMBER(1)                         -- FLAG = 1 alors la PROPRIETE EXISTE sinon 0
, TAB_EVENT_FILE_ID            api_core.TAB_ELEMENT_NUMBER_TYPE  -- TABLEAU D'ELEMENTS NUMBER POUR REPRESENTER => IMPORT_PDA.T_XMLFILES.FILE_ID OU IMPORT_PDA.IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED
, TAB_PARCEL_PROPERTIES        api_core.TAB_PROPERTY_TYPE        -- TABLEAU DE PARCEL PROPERTIES => Récuperation des parcel properties crées par le tracing d'encours carrier
, PAYMENT                      api_core.PAYMENT_SUMMARY_TYPE     -- données relatives à la fonctionnalité Payment Summary

, CONSTRUCTOR FUNCTION PARCEL_INFO_TYPE(SELF IN OUT NOCOPY PARCEL_INFO_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PARCEL_INFO_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PARCEL_INFO_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement INFO COLIS
--                du fichier reçu par WEB SERVICES.
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          |
--  V01.200 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.201 | 2016.11.24 | Hocine HAMMOU
--          | Ajout du tableau de parcel properties
--          |
--  V01.202 | 2016.12.21 | Hocine HAMMOU
--          | Ajout des données relatives à la fonctionnalité Payment Summary
-- ***************************************************************************
IS

CONSTRUCTOR FUNCTION PARCEL_INFO_TYPE(SELF IN OUT NOCOPY PARCEL_INFO_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PARCEL_INFO_TYPE( FIRM_PARCEL_ID          => NULL
                           , FIRM_ID                 => NULL
                           , BO_PARCEL_ID            => NULL
                           , CREATOR                 => NULL
                           , KEEPING_PERIOD          => NULL
 -- 2015.07.10 remplacé -- , SITE_ID   => NULL
                           , INTERNATIONAL_SITE_ID   => NULL
                           , CODAMOUNT               => NULL
                           , CUSTOMER_NAME           => NULL
                           , SHIPPING_DTM            => NULL
                           , MAPPED_PARCEL_STATE     => NULL
                           , MAPPED_PARCEL_STATE_DTM => NULL
                           , Q_DAMAGED_PARCEL        => NULL
                           , Q_OPEN_PARCEL           => NULL
                           , TAB_EVENT_FILE_ID       => NULL -- TABLEAU D'ELEMENTS NUMBER POUR REPRESENTER => IMPORT_PDA.T_XMLFILES.FILE_ID OU IMPORT_PDA.IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED
                           , TAB_PARCEL_PROPERTIES   => NULL -- TABLEAU DE PARCEL PROPERTIES => Récuperation des parcel properties crées par le tracing d'encours carrier
                           , PAYMENT                 => NULL
                           );
RETURN;
END;

END;

/
CREATE OR REPLACE TYPE api_core."PARCEL_SRCH_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PARCEL_SRCH_TYPE
--  DESCRIPTION : Attributs renvoyés par les recherches COLIS
--                par nom de destinataire / sans destinataire / tous ceux du site
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.26 | Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
-- ***************************************************************************
( FIRM_PARCEL_ID               VARCHAR2(50)                -- MASTER.PARCEL.FIRM_PARCEL_CARRIER%TYPE
, FIRM_ID                      VARCHAR2(50)                -- CONFIG.CARRIER.CARRIER_NAME%TYPE
-- 2015.07.10 --, SITE_ID                      INTEGER                   -- MASTER.SITE.SITE_ID%TYPE DEDUIT A PARTIR DES 4 COLONNES SITE_ID DE lA TABLE MASTER.PARCEL
, INTERNATIONAL_SITE_ID        VARCHAR2(35)                -- MASTER.SITE.SITE_ID%TYPE DEDUIT A PARTIR DES 4 COLONNES SITE_ID DE lA TABLE MASTER.PARCEL
, CUSTOMER_NAME                VARCHAR2(151)               -- MASTER.PARCEL.SHIPTO_LASTNAME%TYPE + SHIPTO_FIRSTNAME
, MAPPED_PARCEL_STATE          VARCHAR2(30)                -- FONCTION DE MASTER.PARCEL.CURRENT_STEP_ID ET AUTRE CHOSE
, MAPPED_PARCEL_STATE_DTM      DATE                        -- MASTER.PARCEL.CURRENT_STATE_DTM

, CONSTRUCTOR FUNCTION PARCEL_SRCH_TYPE(SELF IN OUT NOCOPY PARCEL_SRCH_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL -- ????

/
CREATE OR REPLACE TYPE BODY api_core."PARCEL_SRCH_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PARCEL_SRCH_TYPE
--  DESCRIPTION : Attributs renvoyés par les recherches COLIS
--                tous ceux du site  / par nom de destinataire / sans destinataire
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.26 | Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION PARCEL_SRCH_TYPE(SELF IN OUT NOCOPY PARCEL_SRCH_TYPE)
                                              RETURN SELF AS RESULT
  IS
  BEGIN
    SELF := PARCEL_SRCH_TYPE( FIRM_PARCEL_ID          => NULL
                            , FIRM_ID                 => NULL
                            -- 2015.07.10  --, SITE_ID                 => NULL
                            , INTERNATIONAL_SITE_ID   => NULL
                            , CUSTOMER_NAME           => NULL
                            , MAPPED_PARCEL_STATE     => NULL
                            , MAPPED_PARCEL_STATE_DTM => NULL
                            );
    RETURN;
  END;

END;



/
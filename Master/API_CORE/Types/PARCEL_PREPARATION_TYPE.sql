CREATE OR REPLACE TYPE api_core."PARCEL_PREPARATION_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PARCEL_PREPARATION_TYPE
--  DESCRIPTION : table renvoyée par les recherches COLIS À PRÉPARER
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Maria CASALS
--          | Init
-- ***************************************************************************
( INTERNATIONAL_SITE_ID        VARCHAR2(35)                -- MASTER.SITE.SITE_ID%TYPE DEDUIT A PARTIR DES 4 COLONNES SITE_ID DE lA TABLE MASTER.PARCEL
, FIRM_PARCEL_ID               VARCHAR2(50)                -- MASTER.PARCEL.FIRM_PARCEL_CARRIER%TYPE
, PARCEL_RECIPIENT_NAME        VARCHAR2(151)               -- MASTER.PARCEL.SHIPTO_LASTNAME%TYPE + SHIPTO_FIRSTNAME

, CONSTRUCTOR FUNCTION PARCEL_PREPARATION_TYPE(SELF IN OUT NOCOPY PARCEL_PREPARATION_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL -- ????

/
CREATE OR REPLACE TYPE BODY api_core."PARCEL_PREPARATION_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PARCEL_PREPARATION_TYPE
--  DESCRIPTION : table renvoyée par les recherches COLIS À PRÉPARER
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Maria CASALS
--          | Init
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION PARCEL_PREPARATION_TYPE(SELF IN OUT NOCOPY PARCEL_PREPARATION_TYPE)
                                              RETURN SELF AS RESULT
  IS
  BEGIN
    SELF := PARCEL_PREPARATION_TYPE( INTERNATIONAL_SITE_ID   => NULL
                                   , FIRM_PARCEL_ID          => NULL
                                   , PARCEL_RECIPIENT_NAME   => NULL
                                   );
    RETURN;
  END;

END;



/
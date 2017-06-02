CREATE OR REPLACE TYPE api_core."PROPERTY_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PROPERTY_TYPE
--  DESCRIPTION : Description d'une property avec principe clé/valeur
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.15 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--
-- ***************************************************************************
(
  PROPERTY_NAME      VARCHAR2(50)    -- comme CONFIG.PARCEL_PROPERTY.PARCEL_PROPERTY_NAME
, PROPERTY_VALUE     VARCHAR2(3000 ) -- comme MASTER.PARCEL_PROPERTIES.PARCEL_PROPERTY_VALUE
, CONSTRUCTOR FUNCTION PROPERTY_TYPE(SELF IN OUT NOCOPY PROPERTY_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PROPERTY_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PROPERTY_TYPE
--  DESCRIPTION : Description d'une property avec principe clé/valeur
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.15 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION PROPERTY_TYPE(SELF IN OUT NOCOPY PROPERTY_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PROPERTY_TYPE
      (  PROPERTY_NAME        => NULL
      ,  PROPERTY_VALUE       => NULL
      );

   RETURN;
END;

END;


/
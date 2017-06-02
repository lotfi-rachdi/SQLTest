CREATE OR REPLACE TYPE api_core."COMMON_INVENTORY_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.COMMON_INVENTORY_TYPE
--  DESCRIPTION : Description des attributs des INVENTAIRES PDA reçu par WEB API.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
(
  LIBELLE              VARCHAR2(20)    -- IMPORT_PDA.INVENTORY_IMPORTED.LIBELLE
, QUANTITY             NUMBER(3,0)     -- IMPORT_PDA.INVENTORY_IMPORTED.QUANTITY
, INVENTORY_DTM        DATE            -- IMPORT_PDA.INVENTORY_IMPORTED.INVENTORY_DTM
, ORIGIN               VARCHAR2(10)    -- IMPORT_PDA.INVENTORY_IMPORTED.ORIGIN
, CONSTRUCTOR FUNCTION COMMON_INVENTORY_TYPE(SELF IN OUT NOCOPY COMMON_INVENTORY_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."COMMON_INVENTORY_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.COMMON_INVENTORY_TYPE
--  DESCRIPTION : Description des attributs des INVENTAIRES PDA reçu par WEB API.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION COMMON_INVENTORY_TYPE(SELF IN OUT NOCOPY COMMON_INVENTORY_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := COMMON_INVENTORY_TYPE
      (  LIBELLE              => NULL
      ,  QUANTITY             => NULL
      ,  INVENTORY_DTM        => NULL
      ,  ORIGIN               => NULL
      );

   RETURN;
END;

END;

/
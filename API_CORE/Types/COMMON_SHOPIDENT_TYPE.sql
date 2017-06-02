CREATE OR REPLACE TYPE api_core."COMMON_SHOPIDENT_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.COMMON_SHOPIDENT_TYPE
--  DESCRIPTION : Description des attributs des SHOPIDENT PDA reçu par WEB API.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
(
  COUPON_CAB        VARCHAR2(75)         -- IMPORT_PDA.SHOPIDENT_IMPORTED.COUPON_CAB
, RETURN_CODE       NUMBER(3,0)          -- IMPORT_PDA.SHOPIDENT_IMPORTED.RETURN_CODE
, DTM               TIMESTAMP(6)         -- IMPORT_PDA.SHOPIDENT_IMPORTED.DTM

, CONSTRUCTOR FUNCTION COMMON_SHOPIDENT_TYPE(SELF IN OUT NOCOPY COMMON_SHOPIDENT_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."COMMON_SHOPIDENT_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.COMMON_SHOPIDENT_TYPE
--  DESCRIPTION : Description des attributs de SHOPIDENT PDA reçu par WEB API.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION COMMON_SHOPIDENT_TYPE(SELF IN OUT NOCOPY COMMON_SHOPIDENT_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := COMMON_SHOPIDENT_TYPE
      (  COUPON_CAB   => NULL
      ,  RETURN_CODE  => NULL
      ,  DTM          => NULL
      );

   RETURN;
END;

END;

/